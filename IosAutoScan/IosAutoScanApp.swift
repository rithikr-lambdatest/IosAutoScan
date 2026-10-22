import SwiftUI

// =====================================================================
// IosAutoScan — fixture for accessibility autoScan TRIGGER COMMANDS.
// One page per Appium endpoint (/click, /tap, /value, /clear, /swipe,
// /scroll, /longpress, /doubletap, /flick, /actions, /back, /orientation);
// each page hosts the element the gesture is performed on, a live counter
// proving the gesture landed, and ONE empty-label image so every
// triggered scan has an identifiable finding on that page.
// On iOS, driver.back() taps the navigation bar's back button, so every
// page lives in a NavigationView push.
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
            ForEach(pages, id: \.0) { (name, page) in
                NavigationLink(name) { page }
                    .accessibilityIdentifier("open_\(name.lowercased())")
            }
        }
        .navigationTitle("AutoScan Triggers")
    }
}

/// Shared chrome: title + content + the per-page violation (empty-label image).
struct Page<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
            Image(systemName: "info.circle.fill")
                .font(.system(size: 36))
                .accessibilityLabel("")          // per-page violation
            Spacer()
        }
        .padding()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ClickPage: View {
    @State private var count = 0
    var body: some View {
        Page(title: "Click") {
            Button("Click me") { count += 1 }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("btn_click")
            Text("clicks: \(count)").accessibilityIdentifier("click_count")
        }
    }
}

struct TapPage: View {
    @State private var count = 0
    var body: some View {
        Page(title: "Tap") {
            Rectangle().fill(Color.blue.opacity(0.3))
                .frame(height: 120)
                .onTapGesture { count += 1 }
                .accessibilityIdentifier("tap_area")
            Text("taps: \(count)").accessibilityIdentifier("tap_count")
        }
    }
}

struct ValuePage: View {
    @State private var text = ""
    var body: some View {
        Page(title: "Value") {
            TextField("Type here", text: $text)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("input_value")
            Text("typed: \(text)").accessibilityIdentifier("value_echo")
        }
    }
}

struct ClearPage: View {
    @State private var text = "Clear this text"
    var body: some View {
        Page(title: "Clear") {
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("input_clear")
        }
    }
}

/// Drag-family page: counts drags whose travel exceeds the threshold.
struct DragCounterPage: View {
    let title: String
    let areaId: String
    let counterId: String
    let prefix: String
    var minTravel: CGFloat = 60
    @State private var count = 0
    var body: some View {
        Page(title: title) {
            Rectangle().fill(Color.green.opacity(0.3))
                .frame(height: 200)
                .gesture(DragGesture(minimumDistance: minTravel).onEnded { _ in count += 1 })
                .accessibilityIdentifier(areaId)
            Text("\(prefix): \(count)").accessibilityIdentifier(counterId)
        }
    }
}

struct SwipePage: View {
    var body: some View { DragCounterPage(title: "Swipe", areaId: "swipe_area", counterId: "swipe_count", prefix: "swipes") }
}
struct FlickPage: View {
    var body: some View { DragCounterPage(title: "Flick", areaId: "flick_area", counterId: "flick_count", prefix: "flicks") }
}

struct ActionsPage: View {
    @State private var count = 0
    var body: some View {
        Page(title: "Actions") {
            Rectangle().fill(Color.orange.opacity(0.3))
                .frame(height: 200)
                // any pointer sequence counts: tap or drag
                .onTapGesture { count += 1 }
                .simultaneousGesture(DragGesture(minimumDistance: 20).onEnded { _ in count += 1 })
                .accessibilityIdentifier("actions_area")
            Text("gestures: \(count)").accessibilityIdentifier("actions_count")
        }
    }
}

struct ScrollPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 36))
                    .accessibilityLabel("")      // per-page violation
                ForEach(1...40, id: \.self) { i in
                    Text("Row \(i)")
                        .accessibilityIdentifier(i == 40 ? "scroll_bottom" : "row_\(i)")
                }
            }
            .padding()
        }
        .accessibilityIdentifier("scroll_container")
        .navigationTitle("Scroll")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LongPressPage: View {
    @State private var count = 0
    var body: some View {
        Page(title: "LongPress") {
            Rectangle().fill(Color.brown.opacity(0.3))
                .frame(height: 150)
                .onLongPressGesture(minimumDuration: 0.6) { count += 1 }
                .accessibilityIdentifier("longpress_area")
            Text("longpresses: \(count)").accessibilityIdentifier("longpress_count")
        }
    }
}

struct DoubleTapPage: View {
    @State private var count = 0
    var body: some View {
        Page(title: "DoubleTap") {
            Rectangle().fill(Color.purple.opacity(0.3))
                .frame(height: 150)
                .onTapGesture(count: 2) { count += 1 }
                .accessibilityIdentifier("doubletap_area")
            Text("doubletaps: \(count)").accessibilityIdentifier("doubletap_count")
        }
    }
}

struct BackPage: View {
    var body: some View {
        Page(title: "Back") {
            Text("Use driver.back() — it taps the navigation bar back button.")
                .accessibilityIdentifier("back_hint")
        }
    }
}

struct OrientationPage: View {
    @State private var orientation = UIDevice.current.orientation
    var body: some View {
        Page(title: "Orientation") {
            Text("orientation: \(orientation.isLandscape ? "landscape" : "portrait")")
                .accessibilityIdentifier("orientation_label")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            orientation = UIDevice.current.orientation
        }
    }
}
