#require 'ruby-debug'

task :cleanup_event_unicode => :environment do
  Event.all.each do |event|
    # TODO figure out how to encode unicode in db
    if !event.name.scan(/&#[0-9]+;/).empty?
      event.delete
    end
  #  event.name = numberToUnicode(event.name)
  #  event.description = numberToUnicode(event.description)
  #  event.save
  end
end

# &#XXX; to Unicode
def numberToUnicode(str)
  if str.nil?
    return nil
  end
  encodings = str.scan(/&#[0-9]+;/)
  if !encodings.empty?
    unicode = encodings.collect {|e| [e.scan(/[0-9]/)[0].to_i].pack('U*')}
    encodings.each_with_index do |enc, ind|
      str.gsub!(/#{enc}/, unicode[ind])
    end
    debugger
    puts str
  end
  return str
end