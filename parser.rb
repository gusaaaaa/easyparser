def parse(parser_node, html_node, scope)
  if parser_node.empty?
    if html_node.empty?
      result = ParserResult.new valid: true
    else
      result = ParserResult.new valid: false, partial: true, tail: html_node
    end
  else
    case parser_node.type
    when SOMETHING:
      result = parse(parser_node.child, html_node, scope)
      unless result.valid?
        result = parse(parser_node, html_node.next, scope)
      end
    when MANY:
      scope = scope.clone
      result = parse(parser_node.child, html_node, scope)
      unless result.valid?
        if result.partial?
          result.merge parse(parser_node, result.tail, scope)
        end
      end
    when TAG:
      if parser_node.tag == html_node.tag
        result = parse(parser_node.child, html_node.child, scope)
        if result.valid?
          result.merge parse(parser_node.next, html_node.next, scope)
        end
      else
        result = ParserResult.new valid: false
      end
    when TEXT:
      if html_node.text? and parser_node.text == html_node.text
        result = ParserResult.new valid: true, ans: html_node.text
      else
        result = ParserResult.new valid: false
      end
    when REGEX:
      if html_node.text? and parser_node.regexp =~ html_node.text
        result = ParserResult.new valid: true, ans: html_node.text
      else
        result = ParserResult.new valid: false
      end
    when SCOPE:
      scope = scope.clone
      result = parse(parser_node.child, html_node, scope)
    when VARIABLE:
      result = parse(parser_node.child, html_node, scope)
      if result.valid?
        scope[parser_node.variable_name] = result.ans # might be better to return the scope in the result!
      end
    end
  end

  return result
end
