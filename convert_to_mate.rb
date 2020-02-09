require 'nokogiri'
require 'pry'
require 'rufo'

html = File.read("test.html")

@doc = Nokogiri::HTML(html)
@result = {}

def identify_elements(element)
  if (element.elements.any?)
    children = element.elements.map { |e| identify_elements(e) }
    identify_element(element, children)
  else
    identify_element(element, [])
  end
end

def identify_element(element, matestack_children = [])
  case element.name
  when "div"
    <<~SQL.chomp
    div #{identify_attributes(element)} do
    #{matestack_children.join("\n")}
    end
    SQL
  when "p"
    <<~SQL.chomp
    paragraph text: "#{element.text}"
    SQL
  else
    return matestack_children
  end
end

def identify_attributes(element)
  return nil unless element.attributes.any?

  element.attributes.map do |attribute|
    "#{attribute[1].name}:\"#{attribute[1].value}\""
  end.join(",\s")
end

converted = File.write("matestack_component.rb", identify_elements(@doc.elements.first).flatten.join)
result = Rufo::Command.new(false, 0, "", :log).format_file("matestack_component.rb")
puts File.read("matestack_component.rb")
File.delete("matestack_component.rb")
