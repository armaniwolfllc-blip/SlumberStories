import SwiftUI

struct PaywallView: View {
    @ObservedObject var storeManager: StoreManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.05, blue: 0.2).ignoresSafeArea()
            
            VStack(spacing: 25) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill").font(.title).foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                }.padding()

                Text("Dreamy Wolf Premium").font(.largeTitle).bold().foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 15) {
                    Label("Unlimited AI Stories", systemImage: "sparkles")
                    Label("Binaural Sleep Audio", systemImage: "waveform")
                    Label("Save Favorites", systemImage: "star.fill")
                }
                .foregroundColor(.white).padding().background(Color.white.opacity(0.1)).cornerRadius(15)

                Spacer()
                
                Button(action: {
                    Task { if await storeManager.purchasePremium() { dismiss() } }
                }) {
                    Text("Unlock Everything - $7.99/mo")
                        .bold().frame(maxWidth: .infinity).padding().background(Color.yellow).foregroundColor(.black).cornerRadius(30)
                }.padding(.horizontal)
                
                Button("Restore Purchase") {
                    Task { await storeManager.checkPremiumStatus() }
                }.font(.caption).foregroundColor(.gray)
            }.padding()
        }
    }
}
