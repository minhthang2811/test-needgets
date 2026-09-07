// Runs the design file's real renderVals() and diffs it against a transcription
// of the Swift port's derived state, across every prop combination.
const fs = require('fs');

const src = fs.readFileSync('/home/claude/repo/project/Nee.dc.html', 'utf8');
const js = src.match(/<script type="text\/x-dc"[^>]*>([\s\S]*?)<\/script>/)[1];

class DCLogic {
  constructor(props) { this.props = props || {}; }
}
const Component = new Function('DCLogic', js + '\n;return Component;')(DCLogic);

// ---- the Swift port's logic, transcribed ----------------------------------
function swiftDerive({ expression, phase, accessory, arms }) {
  const defaults = { encouraging: 'bothUp', celebrating: 'wide', happy: 'oneUp' };
  let resolvedArms;
  if (arms) resolvedArms = arms;
  else if (accessory !== 'none') resolvedArms = 'hold';
  else resolvedArms = defaults[expression] || 'down';

  return {
    arms: resolvedArms,
    tilt: expression === 'curious' ? 8 : 0,
    faceScale: phase === 'crescent' ? 0.52 : phase === 'half' ? 0.8 : 1,
    faceOffsetX: phase === 'crescent' ? -30 : phase === 'half' ? -13 : 0,
    mask: phase,
    showZ: expression === 'sleepy',
    sparkles: expression === 'celebrating',
    accessory,
  };
}

// ---- normalise the design file's output to the same shape -----------------
function jsDerive(props) {
  const v = new Component(props).renderVals();

  const armName = ['down', 'oneUp', 'bothUp', 'wide', 'hold']
    .find((a) => v['arm_' + a]) || null;

  const tilt = Number(/rotate\((-?[\d.]+)/.exec(v.tilt)[1]);

  let faceScale = 1, faceOffsetX = 0;
  const scaleM = /scale\(([\d.]+)\)/.exec(v.faceTransform);
  if (scaleM) faceScale = Number(scaleM[1]);
  const transM = /^translate\((-?[\d.]+) 0\)/.exec(v.faceTransform);
  if (transM) faceOffsetX = Number(transM[1]);

  const maskName = v.maskUrl === 'none'
    ? 'full'
    : /neeMask(\w+)/.exec(v.maskUrl)[1].toLowerCase();

  const accName = ['hourglass', 'lantern', 'incense', 'teacup', 'envelope', 'blossom']
    .find((a) => v['acc_' + a]) || 'none';

  return {
    arms: armName,
    tilt,
    faceScale,
    faceOffsetX,
    mask: maskName,
    showZ: !!v.showZ,
    sparkles: !!v.celebrate,
    accessory: accName,
  };
}

const EXPRESSIONS = ['neutral', 'happy', 'curious', 'sleepy', 'encouraging', 'thoughtful', 'celebrating'];
const PHASES = ['full', 'gibbous', 'half', 'crescent'];
const ACCESSORIES = ['none', 'hourglass', 'lantern', 'incense', 'teacup', 'envelope', 'blossom'];
const ARMS = ['', 'down', 'oneUp', 'bothUp', 'wide'];

let checked = 0;
const mismatches = [];

for (const expression of EXPRESSIONS)
  for (const phase of PHASES)
    for (const accessory of ACCESSORIES)
      for (const arms of ARMS) {
        const props = { expression, phase, accessory, arms };
        const a = jsDerive(props);
        const b = swiftDerive(props);
        checked++;
        for (const k of Object.keys(a)) {
          if (a[k] !== b[k]) {
            mismatches.push({ props, key: k, design: a[k], swift: b[k] });
          }
        }
      }

// Also confirm the defaults the design file declares match the Swift defaults.
const declared = JSON.parse(
  src.match(/data-props="([^"]*)"/)[1].replace(/&quot;/g, '"')
);
const defaultExpectations = {
  expression: 'neutral', phase: 'full', accessory: 'none', arms: '',
};
for (const [k, want] of Object.entries(defaultExpectations)) {
  const got = declared[k] && declared[k].default;
  if (got !== want) {
    mismatches.push({ props: 'defaults', key: k, design: got, swift: want });
  }
}

console.log(`Prop combinations checked : ${checked}`);
console.log(`Derived values compared   : ${checked * 8 + 4}`);
console.log(`Mismatches                : ${mismatches.length}`);
if (mismatches.length) {
  console.log('\nMISMATCHES');
  for (const m of mismatches.slice(0, 40)) {
    console.log('  ', JSON.stringify(m));
  }
  process.exit(1);
}
console.log('\nSwift logic matches the design file for every prop combination.');
