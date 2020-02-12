require 'nokogiri'
require 'pry'
require 'rufo'

SPECIAL_ATTRIBUTES = {
  "href": "path"
}

MATE_ELEMENT_NAMES = {
  "p" => "paragraph",
  "a" => "link"
}

def identify_elements(element)
  if (element.elements.any?)
    children = element.elements.map { |e| identify_elements(e) }
    identify_element(element, children)
  else
    identify_element(element, [])
  end
end

def identify_element(element, matestack_children = [])
  element_name = MATE_ELEMENT_NAMES[element.name] || element.name
  if matestack_children.any?
    <<~SQL.chomp
    #{element_name} #{identify_attributes(element)} do
    #{matestack_children.join("\n")}
    end
    SQL
  else
    <<~SQL.chomp
    #{element_name} #{identify_attributes(element, true)}
    SQL
  end
end

def identify_attributes(element, no_children = false)
  matt_attributes = element.attributes.to_a.map do |attribute|
    name = SPECIAL_ATTRIBUTES[attribute[1].name] || attribute[1].name
    "#{name}:\"#{attribute[1].value}\""
  end

  matt_attributes << "text:\"#{element.text.strip}\"" if element.children.first&.text.to_s.strip != ""
  matt_attributes.join(",\s")
end

html = File.read("test.html")

@doc = Nokogiri::HTML(html)
@result = {}
result = identify_elements(@doc.elements.first)
File.write("matestack_component.rb", result)
Rufo::Command.new(false, 0, "", :log).format_file("matestack_component.rb")
puts File.read("matestack_component.rb")
File.delete("matestack_component.rb")
