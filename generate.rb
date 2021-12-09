require 'date'
require 'json'
require 'optparse'
require 'set'

BODY_KEY = 'body'
REF_KEY = 'references'
TYPE_KEY = 'type'
TITLE_KEY = 'title'
EN_KEY = 'en'
CN_KEY = 'cn'
ABSTRACT_KEY = 'abstract'
URL_KEY = 'url'
DATE_KEY = 'date'
I18N_KEY = "i18n"

def filter(source)
    filtered = source
    filtered[REF_KEY].delete_if { |ref| ref[TYPE_KEY].empty? }
    filtered
end

def formated_date(date)
    return Date.today if date.nil?
    Date.strptime(date, '%b %d, %Y')
end

def sort(source, output)
    filtered = filter(source)
    source[REF_KEY].sort_by! { |ref| formated_date(ref[DATE_KEY]) }
    source[REF_KEY] = source[REF_KEY].reverse
    File.write(output, JSON.pretty_generate(source))
end

def unique_types(source)
    all_types = source[REF_KEY].map { |ref| ref[TYPE_KEY] }
    all_types.to_set
end

def translate(source, word)
    source[I18N_KEY][word]
end

def generate(source, output)
    lines = []
    lines << '# ' + source[TITLE_KEY][EN_KEY] + ' / ' + source[TITLE_KEY][CN_KEY]
    lines << ''
    lines << source[BODY_KEY][EN_KEY]
    lines << ''
    lines << source[BODY_KEY][CN_KEY]
    lines << ''

    filtered_refs = filter(source)
    sorted_types = unique_types(filtered_refs).sort
    
    lines << '## Category'
    lines << ''
    sorted_types.each do |type|
        i18n = translate(source, type)
        title = if i18n.nil? then type else "#{type} / #{i18n}" end
        lines << "- [#{title}](##{type.downcase})"
    end

    lines << ''
    lines << '---'

    sorted_types.each do |type|
        lines << "## #{type}"
        lines << ''
        typed_refs = filtered_refs[REF_KEY].filter { |ref| ref[TYPE_KEY] == type }
        typed_refs.each do |ref|
            lines << "__#{ref[TITLE_KEY][EN_KEY]}__"
            lines << ''
            lines << "__#{ref[TITLE_KEY][CN_KEY]}__"
            lines << ''
            unless ref[DATE_KEY].nil?
                lines << ref[DATE_KEY]
                lines << ''
            end
            unless ref[ABSTRACT_KEY].nil?
                lines << '_Abstract / 摘要_'
                lines << ''
                lines << ref[ABSTRACT_KEY][EN_KEY]
                lines << ''
                lines << ref[ABSTRACT_KEY][CN_KEY]
                lines << ''
            end
            lines << "[#{ref[URL_KEY]}](#{ref[URL_KEY]})"
            lines << ''
            lines << '[Back to Category / 回到分類](#category)'
            lines << ''
            lines << '---'
        end
    end

    File.write(output, lines.join("\n"))
end

options = {}

OptionParser.new do |opts|
    opts.banner = "Usage: generate.rb [-sort] -input INPUT -output OUTPUT"

    opts.on('-s', '--sort', 'sort') do
        options[:sort] = true
    end

    opts.on('-i', '--input INPUT', 'input file') do |i|
        options[:input] = i
    end

    opts.on('-o', '--output OUTPUT', 'output file') do |o|
        options[:output] = o
    end
end.parse!

file = File.read(options[:input])
source = JSON.parse(file)

if options[:sort]
    sort(source, options[:output])
else
    generate(source, options[:output])
end