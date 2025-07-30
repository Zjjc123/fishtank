import SwiftUI

struct HelpPopupView: View {
  let onClose: () -> Void
  
  var body: some View {
    ZStack {
      // Semi-transparent background
      Color.black.opacity(0.3)
        .edgesIgnoringSafeArea(.all)
        .onTapGesture {
          onClose()
        }
      
      // Content
      VStack(spacing: 20) {
        // Header
        HStack {
          Text("How to Play")
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.primary)
          
          Spacer()
          
          Button(action: onClose) {
            Image(systemName: "xmark.circle.fill")
              .font(.title2)
              .foregroundColor(.gray)
          }
        }
        .padding(.bottom, 5)
        
        // Content in a scrollable view
        ScrollView {
          VStack(alignment: .leading, spacing: 15) {
            helpSection(
              title: "Focus to Earn Fish",
              content: "Set a focus commitment time and complete it to earn new fish for your tank. Longer focus sessions increase your chances of rare fish!",
              icon: "timer"
            )
            
            helpSection(
              title: "Collect Rare Fish",
              content: "There are many fish species to collect, from common to legendary. Complete focus sessions to unlock them all!",
              icon: "star.fill"
            )
            
            helpSection(
              title: "Speed Boosts",
              content: "Purchase speed boosts from the store to make your fish swim faster and more energetically.",
              icon: "bolt.fill"
            )
            
            helpSection(
              title: "Share Your Tank",
              content: "Take screenshots or share your fish collection with friends to show off your focus achievements.",
              icon: "square.and.arrow.up"
            )
            
            helpSection(
              title: "Daily Streaks",
              content: "Maintain a daily focus streak to increase your chances of finding rare fish species.",
              icon: "flame.fill"
            )
          }
          .padding(.horizontal, 5)
        }
        
        Button(action: onClose) {
          Text("Got it!")
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
        }
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 15)
          .fill(.ultraThinMaterial)
          .shadow(color: Color.black.opacity(0.15), radius: 10)
      )
      .padding(20)
      .frame(maxWidth: 500)
    }
  }
  
  private func helpSection(title: String, content: String, icon: String) -> some View {
    HStack(alignment: .top, spacing: 15) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundColor(.blue)
        .frame(width: 30)
      
      VStack(alignment: .leading, spacing: 5) {
        Text(title)
          .font(.headline)
          .foregroundColor(.primary)
        
        Text(content)
          .font(.body)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(.vertical, 5)
  }
}

#Preview {
  ZStack {
    Color.blue.ignoresSafeArea()
    HelpPopupView(onClose: {})
  }
} 