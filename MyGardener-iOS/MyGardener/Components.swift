import SwiftUI

struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(18)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(.white.opacity(0.55), lineWidth: 1))
    }
}

struct MetricPill: View {
    let title: String; let value: String; var subtitle: String = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.bold())
            if !subtitle.isEmpty { Text(subtitle).font(.caption2).foregroundStyle(.secondary) }
        }.frame(maxWidth: .infinity, alignment: .leading)
         .padding(14).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

extension Date {
    var shortDate: String { formatted(.dateTime.month(.abbreviated).day()) }
    var shortDateTime: String { formatted(.dateTime.month(.abbreviated).day().hour().minute()) }
}
