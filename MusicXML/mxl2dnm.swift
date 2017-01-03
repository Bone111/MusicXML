//
//  mxl2dnm.swift
//  MusicXML
//
//  Created by James Bean on 1/3/17.
//
//

import Foundation
import SWXMLHash
// TODO: Import AbstractMusicalModel

// Stub types
struct SpelledPitch {
    let step: String
    let alter: Int
    let octave: Int
}

enum RestOrEvent <T> {
    case rest
    case event(T)
}

struct Duration {
    let beats: Int
    let subdivision: Int
}

struct Note {
    // In `divisions`, for now...
    let duration: Duration
    let restOrEvent: RestOrEvent<[SpelledPitch]>
}

typealias Divisions = Int

public class MusicXML {
    
    // FIXME: Make meaningful
    enum Error: Swift.Error {
        case invalid
    }
    
    // FIXME: This is currently set-up to test a single file
    // - Extend this to test arbitrary files
    public init() {

        let bundle = Bundle(for: MusicXML.self)
        guard
            let url = bundle.url(forResource: "Dichterliebe01", withExtension: "xml")
        else {
            print("Ill-formed URL")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let xml = SWXMLHash.parse(data)
            
            // FIXME: We assume partwise traversal
            // - Implement a check for `score-partwise` vs `score-timewise`
            let score = xml["score-partwise"]
            try traversePartwise(score: score)
            
        } catch {
            print("Something went wrong!")
        }
    }
    
    func traversePartwise(score: XMLIndexer) throws {
        
        for part in score["part"].all {
            
            guard let identifier = part.element?.attribute(by: "id")?.text else {
                throw Error.invalid
            }
            
            print("====================== \(identifier) =======================")
            
            // FIXME: This will generally be set on the first measure
            // - But may change throughout a work
            var divisions: Int = 1
            
            // FIXME: Implement this to:
            // - move forward implicitly after `note` with `duration`
            // - move forward explicitly after `forward` element
            // - move backward explicitly after `backup` element
            var tick: Int = 0
            
            for measure in part["measure"].all {
                
                // FIXME: Clean-up: pull out `division` for the given `part`.
                // - This will generally be set on the first measure
                // - But may change throughout a work
                if
                    let val = measure["attributes"]["divisions"].element?.text,
                    let d = Int(val)
                {
                    divisions = d
                }
                
                for noteXML in measure["note"].all {
                    
                    guard let n = note(from: noteXML, divisions: divisions) else {
                        continue
                    }
                    
                    // Manage changing `divisions` as necessary
                    tick += n.duration.beats
                    print(n)
                }
            }
        }
    }

    // FIXME: Manage `duration` (take into account `division` above)
    func note(from xml: XMLIndexer, divisions: Int) -> Note? {
        
        guard let dur = duration(from: xml, divisions: divisions) else {
            return nil
        }
        
        switch xml["rest"].element {
        case nil:
            return Note(duration: dur, restOrEvent: .event(spelledPitches(from: xml)))
        default:
            return Note(duration: dur, restOrEvent: .rest)
        }
    }
    
    func duration(from note: XMLIndexer, divisions: Int) -> Duration? {
        
        guard
            let beatsString = note["duration"].element?.text,
            let beats = Int(beatsString)
        else {
            return nil
        }
        
        return Duration(beats: beats, subdivision: divisions)
    }

    func spelledPitches(from note: XMLIndexer) -> [SpelledPitch] {

        return note["pitch"].all.flatMap { pitch in
            
            guard
                let step = pitch["step"].element?.text,
                let alter = pitch["alter"].element?.text,
                let octave = pitch["octave"].element?.text
            else {
                return nil
            }
            
            return SpelledPitch(
                step: step,
                alter: Int(alter)!,
                octave: Int(octave)!
            )
        }
    }
}
