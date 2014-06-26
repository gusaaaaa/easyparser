require 'minitest/autorun'
require 'easyparser'

describe EasyParser do

  def test_parsing_nil_should_yield_invalid_result
    source = '
    <html>
      <body>
        <div></div>
        <div></div>
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('<div></div>')

    assert_equal false, result.valid?
  end

  def test_spaces_break_lines_and_comments_should_not_be_taken_into_account
    source = '
    <html>
      <body>
        <div></div>
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run("<html>\r\n  <body>\r\n    <!-- comment -->\r\n    <div></div>\r\n  </body>\r\n</html>")

    assert_equal true, result.valid?
  end

  def test_parsing_tags_without_siblings_yielding_valid_result
    source = '
    <html>
      <body>
        <div></div>
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('<div></div>')

    assert_equal true, result.valid?
  end

  def test_parsing_tags_with_siblings_yielding_valid_result
    source = '
    <html>
      <body>
        <div></div>
        <p></p>
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('<div></div><p></p>')

    assert_equal true, result.valid?
  end

  def test_parsing_tags_yielding_invalid_non_partial_result
    source = '
    <html>
      <body>
        <div></div>
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('<p></p>')

    assert_equal false, result.valid?
    assert_equal false, result.partial?
  end

  def test_parsing_tags_yielding_partial_result
    source = '
    <html>
      <body>
        <div></div>
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('<div><p></p></div>')

    assert_equal false, result.valid?
    assert_equal true, result.partial?
    assert_equal 'p', result.tail.name
  end

  def test_parsing_text_yielding_valid_result
    source = '
    <html>
      <body>
        <div>This is cool!</div>
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('<div>This is cool!</div>')

    assert_equal true, result.valid?
    assert_equal nil, result.ans
  end

  def test_parsing_text_yielding_valid_result_captured_by_variable
    source = '
    <html>
      <body>
        <p>{$var1}This is cool!{/$var1}</p>
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('<p>This is cool!</p>')

    assert_equal true, result.valid?
    assert_equal 'This is cool!', scope['var1']
  end

  def test_scope_is_shared_among_siblings
    source = '
    <html>
      <body>
        <p>{$var1}This is cool!{/$var1}</p>
        <p>{$var2}This is awesome!{/$var2}</p>
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('<p>This is cool!</p><p>This is awesome!</p>')

    assert_equal true, result.valid?
    assert_equal 'This is cool!', scope['var1']
    assert_equal 'This is awesome!', scope['var2']
  end

  def test_many_yielding_valid_result
    source = '
    <html>
      <body>
        {many}
          <p></p>
        {/many}
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('<p></p><p></p><p></p>')

    assert_equal true, result.valid?
  end

  def test_many_yielding_invalid_result
    source = '
    <html>
      <body>
        {many}
          <p></p>
        {/many}
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('<p></p><p></p><span></span>')

    assert_equal false, result.valid?
  end

  def test_something_test_yielding_valid_result
    source = '
    <html>
      <body>
        {...}
        <span></span>
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('<p></p><p></p><span></span>')

    assert_equal true, result.valid?
  end

  def test_something_followed_by_tag_parsing_longer_document_yielding_invalid_result
    source = '
    <html>
      <body>
        {...}
        <span></span>
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('<p></p><p></p><span></span><p></p>')

    assert_equal false, result.valid?
  end

  def test_parsing_regex_yielding_invalid_result
    source = '
    <html>
      <body>
        <div>
          {$var1}{/[0-9]+/}{/$var1}
        </div>
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('<div>Forty two</div>')

    assert_equal false, result.valid?
  end

  def test_parsing_regex_yielding_valid_result_captured_by_variable
    source = '
    <html>
      <body>
        <p>
          {$var1}{/[0-9]+/}{/$var1}
        </p>
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('<p>42</p>')

    assert_equal true, result.valid?
    assert_equal '42', scope['var1']
  end

  def test_block
    source = '
    <html>
      <body>
        <p>
          {$var1}{/[0-9]+/}{/$var1}
        </p>
      </body>
    </html>
    '

    value = nil
    easyparser = EasyParser.new source do |on|
      on.var1 do |scope|
        value = scope['var1']
      end
    end

    result, scope = easyparser.run('<p>42</p>')

    assert_equal true, result.valid?
    assert_equal '42', value
  end

  def test_commands_inside_html_head_yielding_valid_result
    source = '
    <html>
      <head>{...}</head>
      <body>
        <p></p>
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('
      <html>
        <head><title>Hola!</title></head>
        <body>
          <p></p>
        </body>
      </html>
    ')

    assert_equal true, result.valid?
  end

  def test_sandwich_something_inside_many_should_be_allowed
    source = '
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

    easyparser = EasyParser.new source
    result, scope = easyparser.run('
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
    ')

    assert_equal true, result.valid?
  end

  def test_something_followed_by_tag_parsing_empty_node_yielding_invalid_result
    source = '
    <html>
      <body>
        {...}
        <p></p>
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('
      <html>
        <body>
        </body>
      </html>
    ')

    assert_equal false, result.valid?
  end

  def test_tag_followed_by_something_yielding_valid_result
    # opposite scenario as the previous one
    source = '
    <html>
      <body>
        <p></p>
        {...}
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('
      <html>
        <body>
          <p></p>
          <span></span>
        </body>
      </html>
    ')

    assert_equal true, result.valid?
  end

  def test_many_somethings_followed_by_tag_yielding_valid_result
    source = '
    <html>
      <body>
        {many}
          {...}
          <p></p>
        {/many}
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('
      <html>
        <body>
          <span></span>
          <p></p>
          <span></span>
          <p></p>
        </body>
      </html>
    ')

    assert_equal true, result.valid?
  end

  def test_something_but_yielding_valid_result
    source = '
    <html>
      <body>
        {...but}
          <p></p>
        {/...but}
        <div></div>
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('
      <html>
        <body>
          <span></span>
          <span></span>
          <div></div>
        </body>
      </html>
    ')

    assert_equal true, result.valid?
  end

  def test_something_but_yielding_invalid_result
    source = '
    <html>
      <body>
        {...but}
          <p></p>
        {/...but}
        <div></div>
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('
      <html>
        <body>
          <p></p>
          <div></div>
        </body>
      </html>
    ')

    assert_equal false, result.valid?
  end

  def test_something_but_same_element_as_next_should_behave_as_something_operator
    source = '
    <html>
      <body>
        {...but}
          <p></p>
        {/...but}
        <p></p>
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('
      <html>
        <body>
          <span></span>
          <span></span>
          <p></p>
        </body>
      </html>
    ')

    assert_equal true, result.valid?
  end

  def test_something_but_followed_by_nothing_yielding_valid_result
    source = '
    <html>
      <body>
        {...but}
          <p></p>
        {/...but}
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('
      <html>
        <body>
          <span></span>
        </body>
      </html>
    ')

    assert_equal true, result.valid?
  end

  def test_something_but_nothing_should_be_valid
    source = '
    <html>
      <body>
        {...but}
        {/...but}
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('
      <html>
        <body>
          <span></span>
        </body>
      </html>
    ')

    assert_equal true, result.valid?
  end

  def test_something_but_followed_by_tag_evaluating_nothing_should_not_be_valid
    source = '
    <html>
      <body>
        {...but}
        {/...but}
        <p></p>
      </body>
    </html>
    '

    easyparser = EasyParser.new source
    result, scope = easyparser.run('
      <html>
        <body>
        </body>
      </html>
    ')

    assert_equal false, result.valid?
  end

  def test_many_followed_by_something_but_yielding_valid_result
    source = '
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
    easyparser = EasyParser.new source
    result, scope = easyparser.run '
      <html>
        <body>
          <div>
            <p></p>
            <span></span>
          </div>
        </body>
      </html>
    '

    assert_equal true, result.valid?
  end

  def test_scope_should_look_for_variables_in_its_ancestors
    source = '
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

    easyparser = EasyParser.new source do |on|
      on.heading do |scope|
      end
      on.subheading do |scope|
        last_heading = scope['heading']
      end
    end

    result, scope = easyparser.run '
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
    assert_equal true, result.valid?
    assert_equal '2', last_heading
  end

  def test_nested_many_operators
    source = '
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

    easyparser = EasyParser.new source
    result, scope = easyparser.run '
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
    assert_equal true, result.valid?
  end

  def test_many_yielding_partial
    source = '
      <html>
        <body>
          {many}
            <span></span>
          {/many}
        </body>
      </html>
    '

    last_heading = nil

    easyparser = EasyParser.new source

    result, scope = easyparser.run '
      <html>
        <body>
          <span></span>
          <span></span>
          <p></p>
        </body>
      </html>
    '
    assert_equal true, result.partial?
    assert_equal 'p', result.tail.name
  end

  def test_many_should_parse_at_least_one_element
    source = '
      <html>
        <body>
          {many}
            <span></span>
          {/many}
        </body>
      </html>
    '

    easyparser = EasyParser.new source

    result, scope = easyparser.run '
      <html>
        <body>
          <p><p>
        </body>
      </html>
    '
    assert_equal false, result.valid?
    assert_equal false, result.partial?
  end

  def test_either_yielding_valid_result
    source = '
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

    easyparser = EasyParser.new source

    result, scope = easyparser.run '
      <html>
        <body>
          <p></p>
        </body>
      </html>
    '

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
    source = '
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

    easyparser = EasyParser.new source

    result, scope = easyparser.run '
      <html>
        <body>
          <div></div>
        </body>
      </html>
    '

    assert_equal true, result.valid?
  end

  def test_either_order_yielding_invalid_result
    source = '
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

    easyparser = EasyParser.new source

    result, scope = easyparser.run '
      <html>
        <body>
          <span></span>
        </body>
      </html>
    '

    assert_equal false, result.valid?
  end

  def test_either_followed_by_tag_yielding_valid_result
    source = '
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

    easyparser = EasyParser.new source

    result, scope = easyparser.run '
      <html>
        <body>
          <p></p>
          <span></span>
        </body>
      </html>
    '

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
    source = '
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

    easyparser = EasyParser.new source

    result, scope = easyparser.run '
      <html>
        <body>
          <p></p>
          <strong></strong>
        </body>
      </html>
    '

    assert_equal false, result.valid?
  end

  def test_either_evaluating_one_element_yielding_valid_result
    source = '
      <html>
        <body>
          {either}
            <p></p>
          {/either}
        </body>
      </html>
    '

    easyparser = EasyParser.new source

    result, scope = easyparser.run '
      <html>
        <body>
          <p></p>
        </body>
      </html>
    '

    assert_equal true, result.valid?
  end

  def test_either_evaluating_one_element_yielding_invalid_result
    source = '
      <html>
        <body>
          {either}
            <p></p>
          {/either}
        </body>
      </html>
    '

    easyparser = EasyParser.new source

    result, scope = easyparser.run '
      <html>
        <body>
          <div></div>
        </body>
      </html>
    '

    assert_equal false, result.valid?
  end

  def test_regex_capture_should_treat_br_as_regular_text
    source = '
      <html>
        <body>
{/this
is
awesome!/}
        </body>
      </html>
    '

    easyparser = EasyParser.new source

    result, scope = easyparser.run '
      <html>
        <body>this<br />is<br />awesome!</body>
      </html>
    '

    assert_equal true, result.valid?
  end

  def test_regex_capture_should_treat_anchors_as_regular_text
    source = '
      <html>
        <body>
        {/an example of a \[link\]\(http:\/\/example.com\)/}
        </body>
      </html>
    '

    easyparser = EasyParser.new source

    result, scope = easyparser.run '
      <html>
        <body>an example of a <a href="http://example.com">link</a></body>
      </html>
    '

    assert_equal true, result.valid?
  end

  def test_regex_wildcard_should_match_empty_tag
    source = '
      <html>
        <body>{/.*/}</body>
      </html>
    '

    easyparser = EasyParser.new source

    result, scope = easyparser.run '
      <html>
        <body></body>
      </html>
    '

    assert_equal true, result.valid?
  end

  def test_variable_capturing_empty_should_be_valid
    source = '
      <html>
        <body>{$var1}{/.*/}{/$var1}</body>
      </html>
    '

    easyparser = EasyParser.new source do |on|
      on.var1 do |scope|
        assert_equal '', scope['var1']
      end
    end

    result, scope = easyparser.run '
      <html>
        <body></body>
      </html>
    '

    assert_equal true, result.valid?
  end

  def test_regex_should_capture_the_whole_text_concatenation
    source = '
      <html>
        <body><p>{$var1}{/.*/}{/$var1}</p></body>
      </html>
    '

    easyparser = EasyParser.new source do |on|
      on.var1 do |scope|
        assert_equal "This\nis\nawesome!", scope['var1']
      end
    end

    result, scope = easyparser.run '
      <html>
        <body><p>This<br />is<br />awesome!</p></body>
      </html>
    '

    assert_equal true, result.valid?
  end

  def test_variables_enclosed_in_either_should_share_the_same_scope_as_variables_outside
    source = '
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

    easyparser = EasyParser.new source do |on|
      on.var2 do |scope|
        var1 = scope['var1']
      end
    end

    result, scope = easyparser.run '
      <html>
        <body><p>This is a text</p><span>This is some other text</span></body>
      </html>
    '

    assert_equal true, result.valid?
    assert_equal 'This is a text', var1
  end

  def test_regex_should_capture_only_text_br_and_anchors
    source = '
      <html>
        <body>
          <p>{/.*/}</p>
        </body>
      </html>
    '

    easyparser = EasyParser.new source

    result, scope = easyparser.run '
      <html>
        <body>
          <p>This is <span>some text</span></p>
        </body>
      </html>
    '

    assert_equal false, result.valid?
  end

end
