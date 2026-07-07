import SwiftUI
import CoreImage

// MARK: - App Entry
// 使用说明：在 iPad 上打开 Swift Playgrounds → + 新建 App
// → 删除 ContentView.swift → 把本文件全部内容粘贴到 MyApp.swift → 点 ▶️ 运行

@main
struct kuCarApp: App {
    @StateObject private var state = CarState()
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $state.path) {
                HomeScreen().navigationDestination(for: Screen.self) { $0.view }
            }
            .environmentObject(state)
        }
    }
}

// MARK: - State
class CarState: ObservableObject {
    @Published var path = NavigationPath()
    @Published var carImage = SampleCar.sedan()
    @Published var preview: UIImage?

    func startDemo() { carImage = SampleCar.sedan(); preview = carImage; path.append(Screen.editor) }
    func startSUV()  { carImage = SampleCar.suv(); preview = carImage; path.append(Screen.editor) }
}

enum Screen: Hashable {
    case editor
    var view: some View { ColorScreen() }
}

// MARK: - Home
struct HomeScreen: View {
    @EnvironmentObject var s: CarState
    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)
            Image(systemName: "car.2.fill").font(.system(size: 64))
                .foregroundStyle(LinearGradient(colors: [.blue,.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
            Text("kuCar Demo").font(.largeTitle.bold())
            Text("汽车改色膜模拟").font(.title3).foregroundColor(.secondary)

            VStack(spacing: 12) {
                Card(icon: "play.fill", color: .blue, title: "快速体验", subtitle: "轿车改色") { s.startDemo() }
                Card(icon: "car.fill", color: .green, title: "SUV 体验", subtitle: "SUV改色") { s.startSUV() }
            }.padding(.horizontal)
            Spacer()
        }.navigationTitle("kuCar")
    }
}

struct Card: View {
    let icon: String; let color: Color; let title: String; let subtitle: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon).font(.title2).foregroundColor(color)
                    .frame(width: 44, height: 44).background(color.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 4) { Text(title).font(.headline); Text(subtitle).font(.caption).foregroundColor(.secondary) }
                Spacer(); Image(systemName: "chevron.right").foregroundColor(.secondary)
            }.padding().background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Color Editor
struct ColorScreen: View {
    @EnvironmentObject var s: CarState
    @State private var colorIdx = 0
    @State private var finish: Int = 0
    @State private var intensity: Float = 0.85
    @State private var result: UIImage?
    @State private var working = false

    let finishes = ["光泽","哑光","缎面"]
    let colors: [(String, Color)] = [
        ("极光蓝", Color(hex:"#1E3A8A")),("魂动红", Color(hex:"#DC2626")),
        ("英伦绿", Color(hex:"#166534")),("太阳黄", Color(hex:"#FBBF24")),
        ("竞速橙", Color(hex:"#F97316")),("皇家紫", Color(hex:"#7C3AED")),
        ("芭比粉", Color(hex:"#EC4899")),("曜石黑", Color(hex:"#1A1A1A")),
        ("珍珠白", Color(hex:"#F8FAFC")),("钛银", Color(hex:"#C0C0C0")),
        ("金色", Color(hex:"#D97706")),("天蓝", Color(hex:"#3B82F6")),
        ("酒红", Color(hex:"#991B1B")),("薄荷绿", Color(hex:"#34D399")),
        ("石墨灰", Color(hex:"#4B5563")),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Preview
            ZStack {
                Image(uiImage: result ?? s.carImage)
                    .resizable().aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                if working { ProgressView().scaleEffect(1.5).frame(maxWidth:.infinity,maxHeight:.infinity).background(.ultraThinMaterial) }
            }
            .frame(maxHeight: UIScreen.main.bounds.height * 0.42)
            .background(Color(.systemGray6)).padding(8)

            Divider()

            // Controls
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("颜色").font(.subheadline).foregroundColor(.secondary)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(),spacing:6), count: 5), spacing: 6) {
                        ForEach(Array(colors.enumerated()), id: \.offset) { i, c in
                            Button {
                                colorIdx = i
                            } label: {
                                VStack(spacing: 2) {
                                    Circle().fill(c.1).frame(width: 36, height: 36)
                                        .overlay(Circle().stroke(i == colorIdx ? .blue : .clear, lineWidth: 3))
                                    Text(c.0).font(.system(size: 9)).lineLimit(1)
                                }
                            }
                        }
                    }

                    Text("材质").font(.subheadline).foregroundColor(.secondary)
                    Picker("", selection: $finish) {
                        ForEach(Array(finishes.enumerated()), id: \.offset) { i, f in Text(f).tag(i) }
                    }.pickerStyle(.segmented)

                    HStack {
                        Text("强度 \(Int(intensity*100))%").font(.subheadline).foregroundColor(.secondary)
                        Slider(value: $intensity, in: 0.3...1.0).tint(.blue)
                    }

                    Button {
                        applyColor()
                    } label: {
                        Label(working ? "处理中..." : "应用改色", systemImage: "checkmark")
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent).disabled(working)

                    Button("恢复原图") { result = s.carImage }.font(.caption)

                    if let img = result {
                        Button {
                            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                        } label: {
                            Label("保存到相册", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                        }.buttonStyle(.bordered)
                    }
                }.padding()
            }
        }
        .navigationTitle("改色").navigationBarTitleDisplayMode(.inline)
        .onAppear { result = s.carImage }
    }

    func applyColor() {
        working = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            result = ColorEngine.apply(to: s.carImage, color: colors[colorIdx].1, finishIdx: finish, intensity: intensity)
            working = false
        }
    }
}

// MARK: - Color Engine (Core Image)
enum ColorEngine {
    static func apply(to image: UIImage, color: Color, finishIdx: Int, intensity: Float) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let ci = CIImage(cgImage: cg)
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = Float(r), gi = Float(g), bi = Float(b)

        // Grayscale
        guard let mono = colorMatrix(ci,
            rv: CIVector(x:0.2126,y:0.7152,z:0.0722,w:0),
            gv: CIVector(x:0.2126,y:0.7152,z:0.0722,w:0),
            bv: CIVector(x:0.2126,y:0.7152,z:0.0722,w:0)) else { return nil }

        // Tint
        guard let tint = colorMatrix(mono,
            rv: CIVector(x:CGFloat(ri*intensity),y:0,z:0,w:0),
            gv: CIVector(x:0,y:CGFloat(gi*intensity),z:0,w:0),
            bv: CIVector(x:0,y:0,z:CGFloat(bi*intensity),w:0)) else { return nil }

        // Blend
        var result = tint
        if let soft = CIFilter(name: "CISoftLightBlendMode") {
            soft.setValue(tint, forKey: kCIInputImageKey)
            soft.setValue(ci, forKey: kCIInputBackgroundImageKey)
            if let out = soft.outputImage { result = out }
        }

        // Finish
        let contrasts: [Float] = [1.15, 0.85, 1.05]
        let sats: [Float] = [1.1, 0.9, 1.0]
        result = result.applyingFilter("CIColorControls", parameters: [
            kCIInputContrastKey: contrasts[finishIdx],
            kCIInputSaturationKey: sats[finishIdx]
        ])
        if finishIdx == 0 {
            result = result.applyingFilter("CISharpenLuminance", parameters: [kCIInputSharpnessKey: 0.3])
        }

        let ctx = CIContext()
        guard let out = ctx.createCGImage(result, from: result.extent) else { return nil }
        return UIImage(cgImage: out)
    }

    private static func colorMatrix(_ img: CIImage, rv: CIVector, gv: CIVector, bv: CIVector) -> CIImage? {
        guard let f = CIFilter(name: "CIColorMatrix") else { return nil }
        f.setValue(img, forKey: kCIInputImageKey)
        f.setValue(rv, forKey: "inputRVector"); f.setValue(gv, forKey: "inputGVector")
        f.setValue(bv, forKey: "inputBVector")
        f.setValue(CIVector(x:0,y:0,z:0,w:1), forKey: "inputAVector")
        return f.outputImage
    }
}

// MARK: - Sample Cars
enum SampleCar {
    static func sedan() -> UIImage {
        let w: CGFloat = 800, h: CGFloat = 450
        return UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { ctx in
            // Sky
            let colors = [UIColor(red:0.6,green:0.8,blue:1,alpha:1).cgColor, UIColor(red:0.9,green:0.95,blue:1,alpha:1).cgColor]
            ctx.cgContext.drawLinearGradient(CGGradient(colorsSpace:CGColorSpaceCreateDeviceRGB(),colors:colors as CFArray,locations:[0,1])!, start: .zero, end: CGPoint(x:0,y:h*0.6), options:[])
            // Ground
            ctx.cgContext.setFillColor(UIColor(white:0.75,alpha:1).cgColor)
            ctx.cgContext.fill(CGRect(x:0,y:h*0.65,width:w,height:h*0.35))
            // Car body
            let body = UIBezierPath()
            body.move(to: CGPoint(x:w*0.08,y:h*0.62))
            body.addLine(to: CGPoint(x:w*0.25,y:h*0.35))
            body.addLine(to: CGPoint(x:w*0.38,y:h*0.2))
            body.addLine(to: CGPoint(x:w*0.62,y:h*0.2))
            body.addLine(to: CGPoint(x:w*0.75,y:h*0.35))
            body.addLine(to: CGPoint(x:w*0.88,y:h*0.4))
            body.addLine(to: CGPoint(x:w*0.92,y:h*0.62))
            body.close()
            ctx.cgContext.setFillColor(UIColor.darkGray.cgColor)
            ctx.cgContext.addPath(body.cgPath); ctx.cgContext.fillPath()
            // Windows
            ctx.cgContext.setFillColor(UIColor(red:0.2,green:0.25,blue:0.35,alpha:0.85).cgColor)
            ctx.cgContext.fill(CGRect(x:w*0.28,y:h*0.28,width:w*0.44,height:h*0.18))
            // Wheels
            for x in [0.2,0.42,0.65,0.82] {
                let cx = w*CGFloat(x), cy = h*0.65
                ctx.cgContext.setFillColor(UIColor.black.cgColor)
                ctx.cgContext.fillEllipse(in: CGRect(x:cx-32,y:cy-32,width:64,height:64))
                ctx.cgContext.setFillColor(UIColor(white:0.7,alpha:1).cgColor)
                ctx.cgContext.fillEllipse(in: CGRect(x:cx-18,y:cy-18,width:36,height:36))
            }
            // Lights
            ctx.cgContext.setFillColor(UIColor(white:0.9,alpha:0.8).cgColor)
            ctx.cgContext.fillEllipse(in: CGRect(x:w*0.09,y:h*0.38,width:20,height:12))
            ctx.cgContext.setFillColor(UIColor.red.withAlphaComponent(0.7).cgColor)
            ctx.cgContext.fillEllipse(in: CGRect(x:w*0.89,y:h*0.42,width:16,height:12))
        }
    }
    static func suv() -> UIImage {
        let w: CGFloat = 800, h: CGFloat = 480
        return UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { ctx in
            ctx.cgContext.setFillColor(UIColor(white:0.88,alpha:1).cgColor)
            ctx.cgContext.fill(CGRect(origin:.zero, size:CGSize(width:w,height:h)))
            let body = UIBezierPath()
            body.move(to: CGPoint(x:60,y:300)); body.addLine(to: CGPoint(x:80,y:180))
            body.addLine(to: CGPoint(x:150,y:120)); body.addLine(to: CGPoint(x:500,y:120))
            body.addLine(to: CGPoint(x:680,y:160)); body.addLine(to: CGPoint(x:730,y:280))
            body.addLine(to: CGPoint(x:740,y:310)); body.addLine(to: CGPoint(x:60,y:310))
            body.close()
            ctx.cgContext.setFillColor(UIColor.darkGray.cgColor)
            ctx.cgContext.addPath(body.cgPath); ctx.cgContext.fillPath()
            ctx.cgContext.setFillColor(UIColor(red:0.2,green:0.25,blue:0.35,alpha:0.85).cgColor)
            ctx.cgContext.fill(CGRect(x:160,y:130,width:330,height:140))
            for x in [0.16,0.48,0.68,0.9] {
                let cx = w*CGFloat(x), cy = h*0.65
                ctx.cgContext.setFillColor(UIColor.black.cgColor)
                ctx.cgContext.fillEllipse(in: CGRect(x:cx-36,y:cy-36,width:72,height:72))
                ctx.cgContext.setFillColor(UIColor(white:0.7,alpha:1).cgColor)
                ctx.cgContext.fillEllipse(in: CGRect(x:cx-20,y:cy-20,width:40,height:40))
            }
        }
    }
}

// MARK: - Helpers
extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in:.whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count==6, let v=UInt(h,radix:16) else { return nil }
        self.init(red:Double((v>>16)&0xFF)/255, green:Double((v>>8)&0xFF)/255, blue:Double(v&0xFF)/255)
    }
}
