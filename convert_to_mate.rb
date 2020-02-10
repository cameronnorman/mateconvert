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
    paragraph #{identify_attributes(element, true)}"
    SQL
  when "a"
    <<~SQL.chomp
    link #{identify_attributes(element, true)}"
    SQL
  else
    return matestack_children
  end
end

SPECIAL_ATTRIBUTES = {
  "href": "path"
}

def identify_attributes(element, no_children = false)
  matt_attributes = element.attributes.to_a.map do |attribute|
    name = SPECIAL_ATTRIBUTES[attribute[1].name] || attribute[1].name
    "#{name}:\"#{attribute[1].value}\""
  end

  matt_attributes << "text:\"#{element.text}" if no_children
  matt_attributes.join(",\s")
end

result = identify_elements(@doc.elements.first).flatten.join
File.write("matestack_component.rb", result)
Rufo::Command.new(false, 0, "", :log).format_file("matestack_component.rb")
puts File.read("matestack_component.rb")
File.delete("matestack_component.rb")
