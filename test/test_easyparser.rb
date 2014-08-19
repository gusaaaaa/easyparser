require 'test/unit'
require 'easyparser'

class TestParser < Test::Unit::TestCase

  def test_parsing_nil_should_yield_invalid_result
    html_source = '<div></div>'
    ep_template = '
    <html>
      <body>
        <div></div>
        <div></div>
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal false, result.valid?
  end

  def test_spaces_break_lines_and_comments_should_not_be_taken_into_account
    html_source = "<html>\r\n  <body>\r\n    <!-- comment -->\r\n    <div></div>\r\n  </body>\r\n</html>"
    ep_template = '
    <html>
      <body>
        <div></div>
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end

  def test_parsing_tags_without_siblings_yielding_valid_result
    html_source = '<div></div>'
    ep_template = '
    <html>
      <body>
        <div></div>
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end

  def test_parsing_tags_with_siblings_yielding_valid_result
    html_source = '<div></div><p></p>'
    ep_template = '
    <html>
      <body>
        <div></div>
        <p></p>
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end

  def test_parsing_tags_yielding_invalid_non_partial_result
    html_source = '<p></p>'
    ep_template = '
    <html>
      <body>
        <div></div>
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal false, result.valid?
    assert_equal false, result.partial?
  end

  def test_parsing_tags_yielding_partial_result
    html_source = '<div><p></p></div>'
    ep_template = '
    <html>
      <body>
        <div></div>
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal false, result.valid?
    assert_equal true, result.partial?
    assert_equal 'p', result.tail.name
  end

  def test_parsing_text_yielding_valid_result
    html_source = '<div>This is cool!</div>'
    ep_template = '
    <html>
      <body>
        <div>This is cool!</div>
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
    assert_equal nil, result.ans
  end

  def test_parsing_text_yielding_valid_result_captured_by_variable
    html_source = '<p>This is cool!</p>'
    ep_template = '
    <html>
      <body>
        <p>{$var1}This is cool!{/$var1}</p>
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
    assert_equal 'This is cool!', scope['var1']
  end

  def test_scope_is_shared_among_siblings
    html_source = '<p>This is cool!</p><p>This is awesome!</p>'
    ep_template = '
    <html>
      <body>
        <p>{$var1}This is cool!{/$var1}</p>
        <p>{$var2}This is awesome!{/$var2}</p>
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
    assert_equal 'This is cool!', scope['var1']
    assert_equal 'This is awesome!', scope['var2']
  end

  def test_many_yielding_valid_result
    html_source = '<p></p><p></p><p></p>'
    ep_template = '
    <html>
      <body>
        {many}
          <p></p>
        {/many}
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end

  def test_many_yielding_invalid_result
    html_source = '<p></p><p></p><span></span>'
    ep_template = '
    <html>
      <body>
        {many}
          <p></p>
        {/many}
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal false, result.valid?
  end

  def test_something_test_yielding_valid_result
    html_source = '<p></p><p></p><span></span>'
    ep_template = '
    <html>
      <body>
        {...}
        <span></span>
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end

  def test_something_followed_by_tag_parsing_longer_document_yielding_invalid_result
    html_source = '<p></p><p></p><span></span><p></p>'
    ep_template = '
    <html>
      <body>
        {...}
        <span></span>
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal false, result.valid?
  end

  def test_parsing_regex_yielding_invalid_result
    html_source = '<div>Forty two</div>'
    ep_template = '
    <html>
      <body>
        <div>
          {$var1}{/[0-9]+/}{/$var1}
        </div>
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal false, result.valid?
  end

  def test_parsing_regex_yielding_valid_result_captured_by_variable
    html_source = '<p>42</p>'
    ep_template = '
    <html>
      <body>
        <p>
          {$var1}{/[0-9]+/}{/$var1}
        </p>
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
    assert_equal '42', scope['var1']
  end

  def test_block
    html_source = '<p>42</p>'
    ep_template = '
    <html>
      <body>
        <p>
          {$var1}{/[0-9]+/}{/$var1}
        </p>
      </body>
    </html>
    '

    value = nil
    easyparser = EasyParser.new ep_template do |on|
      on.var1 do |scope|
        value = scope['var1']
      end
    end

    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
    assert_equal '42', value
  end

  def test_commands_inside_html_head_yielding_valid_result
    html_source = '
      <html>
        <head><title>Hola!</title></head>
        <body>
          <p></p>
        </body>
      </html>
    '
    ep_template = '
    <html>
      <head>{...}</head>
      <body>
        <p></p>
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end

  def test_sandwich_something_inside_many_should_be_allowed
    html_source = '
      <html>
        <body>
          <span></span>
          <p></p>
          <div></div>
          <span></span>
          <p></p>
          <div></div>
        </body>
      </html>
    '
    ep_template = '
    <html>
      <body>
        {many}
          {...}
            <p></p>
          {...}
        {/many}
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end

  def test_something_followed_by_tag_parsing_empty_node_yielding_invalid_result
    html_source = '
      <html>
        <body>
        </body>
      </html>
    '
    ep_template = '
    <html>
      <body>
        {...}
        <p></p>
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal false, result.valid?
  end

  def test_tag_followed_by_something_yielding_valid_result
    html_source = '
      <html>
        <body>
          <p></p>
          <span></span>
        </body>
      </html>
    '
    # opposite scenario as the previous one
    ep_template = '
    <html>
      <body>
        <p></p>
        {...}
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end

  def test_many_somethings_followed_by_tag_yielding_valid_result
    html_source = '
      <html>
        <body>
          <span></span>
          <p></p>
          <span></span>
          <p></p>
        </body>
      </html>
    '
    ep_template = '
    <html>
      <body>
        {many}
          {...}
          <p></p>
        {/many}
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end

  def test_something_but_yielding_valid_result
    html_source = '
      <html>
        <body>
          <span></span>
          <span></span>
          <div></div>
        </body>
      </html>
    '
    ep_template = '
    <html>
      <body>
        {...but}
          <p></p>
        {/...but}
        <div></div>
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end

  def test_something_but_yielding_invalid_result
    html_source = '
      <html>
        <body>
          <p></p>
          <div></div>
        </body>
      </html>
    '
    ep_template = '
    <html>
      <body>
        {...but}
          <p></p>
        {/...but}
        <div></div>
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal false, result.valid?
  end

  def test_something_but_same_element_as_next_should_behave_as_something_operator
    html_source = '
      <html>
        <body>
          <span></span>
          <span></span>
          <p></p>
        </body>
      </html>
    '
    ep_template = '
    <html>
      <body>
        {...but}
          <p></p>
        {/...but}
        <p></p>
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end

  def test_something_but_followed_by_nothing_yielding_valid_result
    html_source = '
      <html>
        <body>
          <span></span>
        </body>
      </html>
    '
    ep_template = '
    <html>
      <body>
        {...but}
          <p></p>
        {/...but}
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end

  def test_something_but_nothing_should_be_valid
    html_source = '
      <html>
        <body>
          <span></span>
        </body>
      </html>
    '
    ep_template = '
    <html>
      <body>
        {...but}
        {/...but}
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end

  def test_something_but_followed_by_tag_evaluating_nothing_should_not_be_valid
    html_source = '
      <html>
        <body>
        </body>
      </html>
    '
    ep_template = '
    <html>
      <body>
        {...but}
        {/...but}
        <p></p>
      </body>
    </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal false, result.valid?
  end

  def test_many_followed_by_something_but_yielding_valid_result
    html_source = '
      <html>
        <body>
          <div>
            <p></p>
            <span></span>
          </div>
        </body>
      </html>
    '
    ep_template = '
      <html>
        <body>
          <div>
            {many}
              <p></p>
            {/many}
            {...but}<div></div>{/...but}
          </div>
        </body>
      </html>
    '
    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end

  def test_scope_should_look_for_variables_in_its_ancestors
    html_source = '
      <html>
        <body>
          <h1>1</h1>
          <h2>1.1</h2>
          <h2>1.2</h2>
          <h1>2</h1>
          <h2>2.1</h2>
          <h2>2.2</h2>
        </body>
      </html>
    '
    ep_template = '
      <html>
        <body>
          {many}
            <h1>{$heading}{/.*/}{/$heading}</h1>
            {many}
              <h2>{$subheading}{/.*/}{/$subheading}</h2>
            {/many}
          {/many}
        </body>
      </html>
    '

    last_heading = nil

    easyparser = EasyParser.new ep_template do |on|
      on.heading do |scope|
      end
      on.subheading do |scope|
        last_heading = scope['heading']
      end
    end

    result, scope = easyparser.run html_source
    assert_equal true, result.valid?
    assert_equal '2', last_heading
  end

  def test_nested_many_operators
    html_source = '
      <html>
        <body>
          <span></span>
          <p></p>
          <p></p>
          <span></span>
          <p></p>
        </body>
      </html>
    '
    ep_template = '
      <html>
        <body>
          {many}
            <span></span>
            {many}
              <p></p>
            {/many}
          {/many}
        </body>
      </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source
    assert_equal true, result.valid?
  end

  def test_many_yielding_partial
    html_source = '
      <html>
        <body>
          <span></span>
          <span></span>
          <p></p>
        </body>
      </html>
    '
    ep_template = '
      <html>
        <body>
          {many}
            <span></span>
          {/many}
        </body>
      </html>
    '

    last_heading = nil

    easyparser = EasyParser.new ep_template

    result, scope = easyparser.run html_source
    assert_equal true, result.partial?
    assert_equal 'p', result.tail.name
  end

  def test_many_should_parse_at_least_one_element
    html_source = '
      <html>
        <body>
          <p><p>
        </body>
      </html>
    '
    ep_template = '
      <html>
        <body>
          {many}
            <span></span>
          {/many}
        </body>
      </html>
    '

    easyparser = EasyParser.new ep_template

    result, scope = easyparser.run html_source
    assert_equal false, result.valid?
    assert_equal false, result.partial?
  end

  def test_either_yielding_valid_result
    html_source = '
      <html>
        <body>
          <p></p>
        </body>
      </html>
    '
    ep_template = '
      <html>
        <body>
          {either}
            <p></p>
          {or}
            <div></div>
          {/either}
        </body>
      </html>
    '

    easyparser = EasyParser.new ep_template

    result, scope = easyparser.run html_source

    assert_equal true, result.valid?

    result, scope = easyparser.run '
      <html>
        <body>
          <div></div>
        </body>
      </html>
    '

    assert_equal true, result.valid?
  end

  def test_either_evaluating_elements_in_inverted_order_yielding_valid_result
    html_source = '
      <html>
        <body>
          <div></div>
        </body>
      </html>
    '
    ep_template = '
      <html>
        <body>
          {either}
            <p></p>
          {or}
            <div></div>
          {/either}
        </body>
      </html>
    '

    easyparser = EasyParser.new ep_template

    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end

  def test_either_order_yielding_invalid_result
    html_source = '
      <html>
        <body>
          <span></span>
        </body>
      </html>
    '
    ep_template = '
      <html>
        <body>
          {either}
            <p></p>
          {or}
            <div></div>
          {/either}
        </body>
      </html>
    '

    easyparser = EasyParser.new ep_template

    result, scope = easyparser.run html_source

    assert_equal false, result.valid?
  end

  def test_either_followed_by_tag_yielding_valid_result
    html_source = '
      <html>
        <body>
          <p></p>
          <span></span>
        </body>
      </html>
    '
    ep_template = '
      <html>
        <body>
          {either}
            <p></p>
          {or}
            <div></div>
          {/either}
          <span></span>
        </body>
      </html>
    '

    easyparser = EasyParser.new ep_template

    result, scope = easyparser.run html_source

    assert_equal true, result.valid?

    result, scope = easyparser.run '
      <html>
        <body>
          <div></div>
          <span></span>
        </body>
      </html>
    '

    assert_equal true, result.valid?
  end

  def test_either_followed_by_tag_yielding_invalid_result
    html_source = '
      <html>
        <body>
          <p></p>
          <strong></strong>
        </body>
      </html>
    '
    ep_template = '
      <html>
        <body>
          {either}
            <p></p>
          {or}
            <div></div>
          {/either}
          <span></span>
        </body>
      </html>
    '

    easyparser = EasyParser.new ep_template

    result, scope = easyparser.run html_source

    assert_equal false, result.valid?
  end

  def test_either_evaluating_one_element_yielding_valid_result
    html_source = '
      <html>
        <body>
          <p></p>
        </body>
      </html>
    '
    ep_template = '
      <html>
        <body>
          {either}
            <p></p>
          {/either}
        </body>
      </html>
    '

    easyparser = EasyParser.new ep_template

    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end

  def test_either_evaluating_one_element_yielding_invalid_result
    html_source = '
      <html>
        <body>
          <div></div>
        </body>
      </html>
    '
    ep_template = '
      <html>
        <body>
          {either}
            <p></p>
          {/either}
        </body>
      </html>
    '

    easyparser = EasyParser.new ep_template

    result, scope = easyparser.run html_source

    assert_equal false, result.valid?
  end

  def test_regex_capture_should_treat_br_as_regular_text
    html_source = '
      <html>
        <body>this<br />is<br />awesome!</body>
      </html>
    '
    ep_template = '
      <html>
        <body>
{/this
is
awesome!/}
        </body>
      </html>
    '

    easyparser = EasyParser.new ep_template

    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end

  def test_regex_capture_should_treat_anchors_as_regular_text
    html_source = '
      <html>
        <body>an example of a <a href="http://example.com">link</a></body>
      </html>
    '
    ep_template = '
      <html>
        <body>
        {/an example of a \[link\]\(http:\/\/example.com\)/}
        </body>
      </html>
    '

    easyparser = EasyParser.new ep_template

    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end

  def test_regex_wildcard_should_match_empty_tag
    html_source = '
      <html>
        <body></body>
      </html>
    '
    ep_template = '
      <html>
        <body>{/.*/}</body>
      </html>
    '

    easyparser = EasyParser.new ep_template

    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end

  def test_variable_capturing_empty_should_be_valid
    html_source = '
      <html>
        <body></body>
      </html>
    '
    ep_template = '
      <html>
        <body>{$var1}{/.*/}{/$var1}</body>
      </html>
    '

    easyparser = EasyParser.new ep_template do |on|
      on.var1 do |scope|
        assert_equal '', scope['var1']
      end
    end

    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end

  def test_regex_should_capture_the_whole_text_concatenation
    html_source = '
      <html>
        <body><p>This<br />is<br />awesome!</p></body>
      </html>
    '
    ep_template = '
      <html>
        <body><p>{$var1}{/.*/}{/$var1}</p></body>
      </html>
    '

    easyparser = EasyParser.new ep_template do |on|
      on.var1 do |scope|
        assert_equal "This\nis\nawesome!", scope['var1']
      end
    end

    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end

  def test_variables_enclosed_in_either_should_share_the_same_scope_as_variables_outside
    html_source = '
      <html>
        <body><p>This is a text</p><span>This is some other text</span></body>
      </html>
    '
    ep_template = '
      <html>
        <body>
          {either}
            <p>{$var1}{/.*/}{/$var1}</p>
          {or}
            <div>{$var1}{/.*/}{/$var1}</div>
          {/either}
          <span>{$var2}{/.*/}{/$var2}</span>
        </body>
      </html>
    '

    var1 = nil

    easyparser = EasyParser.new ep_template do |on|
      on.var2 do |scope|
        var1 = scope['var1']
      end
    end

    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
    assert_equal 'This is a text', var1
  end

  def test_regex_should_capture_only_text_br_and_anchors
    html_source = '
      <html>
        <body>
          <p>This is <span>some text</span></p>
        </body>
      </html>
    '
    ep_template = '
      <html>
        <body>
          <p>{/.*/}</p>
        </body>
      </html>
    '

    easyparser = EasyParser.new ep_template

    result, scope = easyparser.run html_source

    assert_equal false, result.valid?
  end

  def test_something_parser_with_multiple_children
    html_source = '
      <html>
        <body>
          <p>First</p>
          <p>Second</p>
          <p>Third</p>
        </body>
      </html>
    '

    # example 1
    ep_template = '
      <html>
        <body>
          {...}
          <p>{$last}{/.*/}{/$last}</p>
        </body>
      </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
    assert_equal 'Third', scope['last']

    # example 2
    ep_template = '
      <html>
        <body>
          {...}
          <p>Third</p>
        </body>
      </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal true, result.valid?

    # example 3
    ep_template = '
      <html>
        <body>
          {...}
          <p>Second</p>
        </body>
      </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal false, result.valid?
    assert_equal true, result.partial?

    # example 4
    ep_template = '
      <html>
        <body>
          {...}
          <p>{/.*/}</p>
        </body>
      </html>
    '

    easyparser = EasyParser.new ep_template
    result, scope = easyparser.run html_source

    assert_equal true, result.valid?
  end
end
