import SwiftUI

/// The character sheet: all seven expressions, four phases and six accessories
/// on one page, mirroring the "Nhân vật & hệ thống" board from the design.
///
/// This is a development surface — drop it in a preview or a debug screen to
/// check the character renders correctly at a glance. It is not part of the
/// shipping UI.
public struct NeeGallery: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                header

                section(
                    title: "Biểu cảm — bảy trạng thái",
                    note: "Không mũi, không mày. Chỉ mắt và miệng."
                ) {
                    ForEach(NeeExpression.allCases, id: \.self) { expression in
                        tile(caption: expression.vietnameseName, detail: expression.vietnameseNote) {
                            Nee(expression: expression, width: 108)
                        }
                    }
                }

                section(
                    title: "Pha trăng — trục cảm xúc thứ hai",
                    note: "Tròn = hiện diện. Khuyết = nghỉ ngơi."
                ) {
                    ForEach(NeePhase.allCases, id: \.self) { phase in
                        tile(caption: phase.vietnameseName, detail: nil) {
                            Nee(
                                expression: phase == .crescent ? .sleepy : .neutral,
                                phase: phase,
                                width: 108
                            )
                        }
                    }
                }

                section(
                    title: "Phụ kiện — mỗi lần một món",
                    note: "Nee cầm bằng tay, không bao giờ mặc lên người."
                ) {
                    ForEach(NeeAccessory.allCases.filter { $0 != .none }, id: \.self) { accessory in
                        tile(caption: accessory.vietnameseName, detail: nil) {
                            Nee(expression: .neutral, accessory: accessory, width: 108)
                        }
                    }
                }
            }
            .padding(32)
        }
        .background(NeePalette.paper)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NEEDGETS · BẢNG NHÂN VẬT")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .kerning(0.66)
                .foregroundStyle(NeePalette.ink.opacity(0.38))
            Text("Nee, và cái sân khấu yên tĩnh cho Nee")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(NeePalette.ink)
        }
    }

    private func section<Content: View>(
        title: String,
        note: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(NeePalette.ink)
                Text(note)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(NeePalette.ink.opacity(0.6))
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 132), spacing: 16)],
                alignment: .leading,
                spacing: 24
            ) {
                content()
            }
        }
    }

    private func tile<Content: View>(
        caption: String,
        detail: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 10) {
            content()
                .frame(height: NeeMetrics.height(forWidth: 108))

            VStack(spacing: 2) {
                Text(caption)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(NeePalette.ink)
                if let detail {
                    Text(detail)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(NeePalette.ink.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Vietnamese names, as used on the design's character sheet

extension NeeExpression {
    public var vietnameseName: String {
        switch self {
        case .neutral:     return "Bình thường"
        case .happy:       return "Vui vẻ"
        case .curious:     return "Tò mò"
        case .sleepy:      return "Buồn ngủ"
        case .encouraging: return "Khích lệ"
        case .thoughtful:  return "Nghĩ ngợi"
        case .celebrating: return "Ăn mừng"
        }
    }

    var vietnameseNote: String {
        switch self {
        case .neutral:     return "Mắt tròn, miệng cong nhẹ"
        case .happy:       return "Mắt vòng cung, miệng hé"
        case .curious:     return "Một mắt to hơn, nghiêng 8°"
        case .sleepy:      return "Mắt lim dim, một chữ “z”"
        case .encouraging: return "Mắt nhắm, hai tay đưa lên"
        case .thoughtful:  return "Mắt nhìn lên phải, miệng thẳng"
        case .celebrating: return "Mắt hình sao, tay mở rộng"
        }
    }
}

extension NeePhase {
    public var vietnameseName: String {
        switch self {
        case .full:     return "Tròn"
        case .gibbous:  return "Khuyết nhẹ"
        case .half:     return "Bán nguyệt"
        case .crescent: return "Lưỡi liềm"
        }
    }
}

extension NeeAccessory {
    public var vietnameseName: String {
        switch self {
        case .none:      return "Không"
        case .hourglass: return "Đồng hồ cát"
        case .lantern:   return "Đèn giấy"
        case .incense:   return "Nén nhang"
        case .teacup:    return "Chén trà"
        case .envelope:  return "Bao đỏ"
        case .blossom:   return "Cành mai"
        }
    }
}

// MARK: - Previews

#Preview("Character sheet") {
    NeeGallery()
}

#Preview("Sizes") {
    HStack(alignment: .bottom, spacing: 24) {
        Nee(expression: .sleepy, phase: .crescent, width: 44)
        Nee(expression: .thoughtful, width: 96)
        Nee(expression: .celebrating, accessory: .envelope, width: 180)
    }
    .padding(40)
    .background(NeePalette.paper)
}

#Preview("Still, for widgets") {
    HStack(spacing: 24) {
        Nee(expression: .sleepy, phase: .crescent, animated: false, width: 96)
        Nee(expression: .celebrating, animated: false, width: 96)
    }
    .padding(40)
    .background(NeePalette.paper)
}
