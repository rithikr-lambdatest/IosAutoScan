import SwiftUI

// =====================================================================
// IosAutoScan — fixture for accessibility autoScan TRIGGER COMMANDS.
// One page per Appium endpoint. autoScan fires on the command but the scan
// is SKIPPED when the screenshot's 8x8 AVERAGE hash is >95% similar to any
// previous scan. That hash keys on LUMINANCE, not colour — so the bottom
// ~half of every page is a per-page BLACK/WHITE BLOCK GRID (distinct
// pattern per page) that fully INVERTS when the gesture lands, maximising
// the before/after hash distance. The scroll page uses pure black/white
// alternating rows so each scroll step swaps luminance at every position.
// Each page also keeps a live counter and one empty-label image so every
// scan has an identifiable finding. Pages are NavigationView pushes because
// driver.back() taps the nav-bar back button.
// =====================================================================

@main
struct IosAutoScanApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView { HomeView() }
                .navigationViewStyle(.stack)
        }
    }
}

struct HomeView: View {
    private let pages: [(String, AnyView)] = [
        ("Click", AnyView(ClickPage())),
        ("Tap", AnyView(TapPage())),
        ("Value", AnyView(ValuePage())),
        ("Clear", AnyView(ClearPage())),
        ("Swipe", AnyView(SwipePage())),
        ("Scroll", AnyView(ScrollPage())),
        ("LongPress", AnyView(LongPressPage())),
        ("DoubleTap", AnyView(DoubleTapPage())),
        ("Flick", AnyView(FlickPage())),
        ("Actions", AnyView(ActionsPage())),
        ("Back", AnyView(BackPage())),
        ("Orientation", AnyView(OrientationPage())),
    ]
    var body: some View {
        List {
            ForEach(Array(pages.enumerated()), id: \.offset) { (_, item) in
                NavigationLink(item.0) { item.1 }
                    .accessibilityIdentifier("open_\(item.0.lowercased())")
            }
        }
        .navigationTitle("AutoScan Triggers")
    }
}

/// Bottom-half stage panel: a cols×rows black/white grid from `seed`, inverting
/// with `inverted`, plus a red label overlay. Luminance pattern is what moves an
/// 8x8 average hash — colour does not.
struct PatternPanel: View {
    let seed: Int
    let cols: Int
    let rows: Int
    var inverted: Bool
    var label: String
    private func dark(_ r: Int, _ c: Int) -> Bool {
        let v = (r * 7 + c * 13 + seed * 17) % 5
        return (v < 3) != inverted
    }
    var body: some View {
        GeometryReader { geo in
            let cw = geo.size.width / CGFloat(cols)
            let ch = geo.size.height / CGFloat(rows)
            ZStack {
                Canvas { ctx, _ in
                    for r in 0..<rows {
                        for c in 0..<cols {
                            let rect = CGRect(x: CGFloat(c) * cw, y: CGFloat(r) * ch, width: cw + 1, height: ch + 1)
                            ctx.fill(Path(rect), with: .color(dark(r, c) ? .black : .white))
                        }
                    }
                }
                Text(label)
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .accessibilityIdentifier("stage_panel")
    }
}

/// Page chrome: top content, the per-page violation (empty-label image), then the
/// stage panel filling the bottom ~half.
struct Page<Content: View>: View {
    let title: String
    let seed: Int
    @Binding var fired: Bool
    let beforeText: String
    let afterText: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                content
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 34))
                    .accessibilityLabel("")          // per-page violation
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            PatternPanel(seed: seed, cols: 6 + seed % 4, rows: 5 + seed % 3,
                         inverted: fired, label: fired ? afterText : beforeText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ClickPage: View {
    @State private var count = 0
    @State private var fired = false
    var body: some View {
        Page(title: "Click", seed: 1, fired: $fired, beforeText: "CLICK\nWAIT", afterText: "CLICK\nDONE") {
            Button("Click me") { count += 1; fired = true }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("btn_click")
            Text("clicks: \(count)").accessibilityIdentifier("click_count")
        }
    }
}

struct TapPage: View {
    @State private var count = 0
    @State private var fired = false
    var body: some View {
        Page(title: "Tap", seed: 2, fired: $fired, beforeText: "TAP\nWAIT", afterText: "TAP\nDONE") {
            Rectangle().fill(Color.blue.opacity(0.3)).frame(height: 100)
                .onTapGesture { count += 1; fired = true }
                .accessibilityIdentifier("tap_area")
            Text("taps: \(count)").accessibilityIdentifier("tap_count")
        }
    }
}

struct ValuePage: View {
    @State private var text = ""
    @State private var fired = false
    var body: some View {
        Page(title: "Value", seed: 3, fired: $fired, beforeText: "VALUE\nEMPTY", afterText: "VALUE\nTYPED") {
            TextField("Type here", text: $text)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("input_value")
                .onChange(of: text) { fired = !$0.isEmpty }
        }
    }
}

struct ClearPage: View {
    @State private var text = "Clear this text"
    @State private var fired = false
    var body: some View {
        Page(title: "Clear", seed: 4, fired: $fired, beforeText: "CLEAR\nHAS TEXT", afterText: "CLEAR\nEMPTY") {
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("input_clear")
                .onChange(of: text) { fired = $0.isEmpty }
        }
    }
}

struct DragCounterPage: View {
    let title: String; let seed: Int; let areaId: String; let counterId: String; let prefix: String
    var minTravel: CGFloat = 60
    @State private var count = 0
    @State private var fired = false
    var body: some View {
        Page(title: title, seed: seed, fired: $fired, beforeText: "\(prefix.uppercased())\nWAIT", afterText: "\(prefix.uppercased())\nDONE") {
            Rectangle().fill(Color.green.opacity(0.3)).frame(height: 160)
                .gesture(DragGesture(minimumDistance: minTravel).onEnded { _ in count += 1; fired = true })
                .accessibilityIdentifier(areaId)
            Text("\(prefix): \(count)").accessibilityIdentifier(counterId)
        }
    }
}

struct SwipePage: View { var body: some View { DragCounterPage(title: "Swipe", seed: 5, areaId: "swipe_area", counterId: "swipe_count", prefix: "swipes") } }
struct FlickPage: View { var body: some View { DragCounterPage(title: "Flick", seed: 9, areaId: "flick_area", counterId: "flick_count", prefix: "flicks") } }

struct ActionsPage: View {
    @State private var count = 0
    @State private var fired = false
    var body: some View {
        Page(title: "Actions", seed: 10, fired: $fired, beforeText: "ACTIONS\nWAIT", afterText: "ACTIONS\nDONE") {
            Rectangle().fill(Color.orange.opacity(0.3)).frame(height: 160)
                .onTapGesture { count += 1; fired = true }
                .simultaneousGesture(DragGesture(minimumDistance: 20).onEnded { _ in count += 1; fired = true })
                .accessibilityIdentifier("actions_area")
            Text("gestures: \(count)").accessibilityIdentifier("actions_count")
        }
    }
}

struct ScrollPage: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 34))
                    .accessibilityLabel("")          // per-page violation
                    .padding(.bottom, 8)
                // Pure black/white alternating rows: each scroll step swaps luminance
                // at every screen position (colour bands sit at similar brightness).
                ForEach(1...40, id: \.self) { i in
                    let dark = i % 2 == 0
                    Text("Row \(i)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(dark ? .white : .black)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(dark ? Color.black : Color.white)
                        .accessibilityIdentifier(i == 40 ? "scroll_bottom" : "row_\(i)")
                }
            }
        }
        .accessibilityIdentifier("scroll_container")
        .navigationTitle("Scroll")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LongPressPage: View {
    @State private var count = 0
    @State private var fired = false
    var body: some View {
        Page(title: "LongPress", seed: 7, fired: $fired, beforeText: "LONGPRESS\nWAIT", afterText: "LONGPRESS\nDONE") {
            Rectangle().fill(Color.brown.opacity(0.3)).frame(height: 130)
                .onLongPressGesture(minimumDuration: 0.6) { count += 1; fired = true }
                .accessibilityIdentifier("longpress_area")
            Text("longpresses: \(count)").accessibilityIdentifier("longpress_count")
        }
    }
}

struct DoubleTapPage: View {
    @State private var count = 0
    @State private var fired = false
    var body: some View {
        Page(title: "DoubleTap", seed: 8, fired: $fired, beforeText: "DOUBLETAP\nWAIT", afterText: "DOUBLETAP\nDONE") {
            Rectangle().fill(Color.purple.opacity(0.3)).frame(height: 130)
                .onTapGesture(count: 2) { count += 1; fired = true }
                .accessibilityIdentifier("doubletap_area")
            Text("doubletaps: \(count)").accessibilityIdentifier("doubletap_count")
        }
    }
}

struct BackPage: View {
    @State private var fired = false
    var body: some View {
        Page(title: "Back", seed: 11, fired: $fired, beforeText: "BACK\nPRESS BACK", afterText: "BACK\nPRESS BACK") {
            Text("Use driver.back() — it taps the navigation bar back button.")
                .accessibilityIdentifier("back_hint")
        }
    }
}

struct OrientationPage: View {
    @State private var orientation = UIDevice.current.orientation
    @State private var fired = false
    var body: some View {
        Page(title: "Orientation", seed: 12, fired: $fired, beforeText: "PORTRAIT", afterText: "LANDSCAPE") {
            Text("orientation: \(orientation.isLandscape ? "landscape" : "portrait")")
                .accessibilityIdentifier("orientation_label")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            orientation = UIDevice.current.orientation
            fired = orientation.isLandscape
        }
    }
}
