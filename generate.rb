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

def generate_toc(source, language)
    filtered_refs = filter(source)
    sorted_types = unique_types(filtered_refs).sort
    lines = []
    lines << (language == :en ? '## Category' : '## 分類')
    lines << ''
    sorted_types.each do |type|
        title = (language == :en ? type : translate(source, type))
        title = type if title.nil?
        lines << "- [#{title}](##{title.downcase.gsub(' ', '-')})"
    end

    lines
end

def generate_content(source, language)
    filtered_refs = filter(source)
    sorted_types = unique_types(filtered_refs).sort

    lines = []
    sorted_types.each do |type|
        type_line = (language == :en ? type : translate(source, type))
        type_line = type if type_line.nil?
        lines << "## #{type_line.upcase}"
        lines << ''
        typed_refs = filtered_refs[REF_KEY].filter { |ref| ref[TYPE_KEY] == type }
        typed_refs.each do |ref|
            lines << (language == :en ? "__#{ref[TITLE_KEY][EN_KEY]}__" : "__#{ref[TITLE_KEY][CN_KEY]}__")
            lines << ''
            unless ref[DATE_KEY].nil?
                lines << ref[DATE_KEY]
                lines << ''
            end
            unless ref[ABSTRACT_KEY].nil?
                lines << (language == :en ? '_Abstract_' : '_摘要_')
                lines << ''
                lines << (language == :en ? ref[ABSTRACT_KEY][EN_KEY] : ref[ABSTRACT_KEY][CN_KEY])
                lines << ''
            end
            lines << "[#{ref[URL_KEY]}](#{ref[URL_KEY]})"
            lines << ''
            lines << (language == :en ? '[Back to Category](#category)' : '[回到分類](#category)')
            lines << ''
            lines << '---'
        end
    end

    lines
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

    lines << generate_toc(source, :en)
    lines << ''
    lines << generate_toc(source, :cn)

    lines << ''
    lines << '---'

    lines << generate_content(source, :en)
    lines << generate_content(source, :cn)

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