MidiFile = include "music/midi/midiFile"
SongBuilder = include "music/builders/songBuilder"
include "utils/arrayUtils"
module.exports =

#------------------------------------------------------------------------------------------
#A MIDI reader that generates *songs* by parsing the file.
class MidiReader
	constructor: (filePath) ->
		@file = new MidiFile filePath
		
	#convert the file to a *song*.
	toSong: =>
		song = new SongBuilder()
		@allEvents().forEach (event) =>
			melody = song.getIddleMelody Math.round(event.playTime)

			melody.add
				note: event.note()
				duration: event.duration
		song.clean()
		song

	#all events of all tracks processed.
	allEvents: =>
		[0 ... @file.totalTracks()]
			.map(@processTrack)
			.flatten()
			.sort((one, another) =>
				if one.playTime <= another.playTime then -1 else 1
			)

	#apply some transformations to the track events.
	processTrack: (track) =>
		process = (result, func) => func result
		notes = @file.noteEventsIn(track).cloneDeep()
		[@_addSilences, @_addDurations].reduce process, notes

	#convert all the "note off" events to silences.
	#the ones that have no duration will be removed.
	_addSilences: (events) =>
		convertSilences = (events, next) =>
			current = events.last()

			if current.isNoteOff()
				current.convertToRest()
				if current.deltaWith(next) is 0
					events.pop()

			events.concat [next]

		events = events.reduce convertSilences, [events.shift()]
		events.last().convertToRest() ; events

	#add to each event its duration.
	_addDurations: (events) =>
		events.map (event, i) =>
			event.duration = event.durationIn events.slice(i)
			event
#------------------------------------------------------------------------------------------