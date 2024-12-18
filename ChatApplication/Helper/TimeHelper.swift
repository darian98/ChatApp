//
//  TimeHelper.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 18.12.24.
//

import Foundation

enum TimeHelper {
    
    // MARK: Function to set the message for timer within a specific chat
    static func configureTimerMessage(seconds: Int) -> String {
        var hours = 0
        var minutes = 0
        var seconds1 = 0
        
        minutes = seconds / 60       // Ganzzahldivision
        seconds1 = seconds % 60
        
        var andMinutes = 0
        var andSeconds = 0
        
        hours = minutes / 60
        print("Stunden: ")
        andMinutes = minutes % 60
        andSeconds = seconds1
        
        let hourOrHours = "\(hours == 1 ? "Stunde" : "Stunden")"
        let minuteOrMinutes = "\(andMinutes == 1 ? "Minute" : "Minuten")"
        let secondOrSeconds = "\(andSeconds == 1 ? "Sekunde" : "Sekunden")"
        
        let hoursText = "\(hours > 0 ? "\(hours) \(hourOrHours)," : "")"
        let minuteText = "\(minutes > 0 ? "\(String(andMinutes)) \(minuteOrMinutes)" : "")"
        let andSecondsText =  "\(minutes > 0 ? "und \(seconds1) \(secondOrSeconds)" : "\(seconds1) \(secondOrSeconds)")"
        
        
        let components = [hoursText, minuteText, andSecondsText].filter { !$0.isEmpty }
        let combinedText = components.joined(separator: " ")
        
        let hoursMinutesAndSecondsText = "Der Timer wurde auf \(combinedText) gesetzt!"
        
        return hoursMinutesAndSecondsText
    }
}
