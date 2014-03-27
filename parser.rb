def parse(parser_node, html_node, scope_chain)
  scope_chain = scope_chain.clone
  if parser_node.empty?
    if html_node.empty?
      result = ParserResult.new valid: true
    else
      result = ParserResult.new valid: false, partial: true, tail: html_node
    end
    new_scope_chain = scope_chain
  else
    case parser_node.type
    when SOMETHING:
      result, new_scope_chain = parse(parser_node.child, html_node, scope_chain)
      unless result.valid?
        # it's not valid, keep trying
        result, new_scope_chain = parse(parser_node, html_node.next, scope_chain)
      end
    when MANY:
      # creates a brand new scope chain per iteration
      per_iteration_scope_chain = scope_chain.clone << Hash.new
      result, new_scope_chain = parse(parser_node.child, html_node, per_iteration_scope_chain)
      unless result.valid?
        if result.partial?
          # partial results, keep iterating
          result, new_scope_chain = parse(parser_node, result.tail, scope_chain)
        end
      end
    when TAG:
      if parser_node.tag == html_node.tag
        result, new_scope_chain = parse(parser_node.child, html_node.child, scope_chain)
        if result.valid?
          temp_result, temp_scope_chain = parse(parser_node.next, html_node.next, new_scope_chain)
          result.merge temp_result
          new_scope_chain.last.merge! temp_scope_chain.last
        end
      else
        result = ParserResult.new valid: false
        new_scope_chain = scope_chain
      end
    when TEXT:
      if html_node.text? and parser_node.text == html_node.text
        result = ParserResult.new valid: true, ans: html_node.text
      else
        result = ParserResult.new valid: false
      end
      new_scope_chain = scope_chain
    when REGEX:
      if html_node.text? and parser_node.regexp =~ html_node.text
        result = ParserResult.new valid: true, ans: html_node.text
      else
        result = ParserResult.new valid: false
      end
      new_scope_chain = scope_chain
    when SCOPE:
      scope_chain << Hash.new
      result, new_scope_chain = parse(parser_node.child, html_node, scope_chain)
    when VARIABLE:
      result, new_scope_chain = parse(parser_node.child, html_node, scope_chain)
      if result.valid?
        new_scope_chain.last[parser_node.variable_name] = result.ans
      end
    end
  end

  return result, new_scope_chain
end
