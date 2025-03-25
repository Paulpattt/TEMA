//
//  TemaWidget.swift
//  TemaWidget
//
//  Created by Paul Paturel on 24/03/2025.
//

import WidgetKit
import SwiftUI

// Extension to handle background compatibility between iOS versions
extension View {
    func widgetBackground(_ backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct TemaWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall, .systemLarge:
            // Small and large widgets - completely empty (background shows the pattern)
            Color.clear
        default:
            // Medium widget - show content on black background
            VStack(spacing: 8) {
                Text("TEMA")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color("TEMA_Red"))
                
                Spacer(minLength: 4)
                
                Text(formattedDate(entry.date))
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer(minLength: 4)
                
                Text("Ouvrir l'application")
                    .font(.caption2)
                    .foregroundColor(Color.gray)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
        }
    }
    
    // Format the date for display
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TemaWidget: Widget {
    let kind: String = "TemaWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            TemaWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    GeometryReader { geometry in
                        // Determine which image to use based on widget family
                        if family(from: geometry) == .systemSmall {
                            // Small widget - use original checkerboard
                            Image("TEMAwidget")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else if family(from: geometry) == .systemLarge {
                            // Large widget - use the larger, complete checkerboard
                            Image("TEMAwidgetMaxi")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .scaledToFit()
                                .position(x: geometry.size.width/2, y: geometry.size.height/2)
                        } else {
                            // Medium widget
                            Color.black
                        }
                    }
                }
                .widgetURL(URL(string: "tema://open"))
        }
        .configurationDisplayName("TEMA Widget")
        .description("Affiche des informations sur TEMA et un damier rouge et noir.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
    
    // Helper function to determine widget family based on geometry
    private func family(from geometry: GeometryProxy) -> WidgetFamily {
        // Small widgets are square and small
        if abs(geometry.size.width - geometry.size.height) < 1.0 && geometry.size.width < 200 {
            return .systemSmall
        }
        // Large widgets are square (or nearly square) and larger
        else if abs(geometry.size.width - geometry.size.height) < 20 {
            return .systemLarge
        }
        // Default to medium for rectangular widgets
        else {
            return .systemMedium
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    TemaWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
}

#Preview(as: .systemMedium) {
    TemaWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
}

#Preview(as: .systemLarge) {
    TemaWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
}
