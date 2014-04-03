# encoding: UTF-8

require 'easyparser'
require 'open-uri'

ep_source = '
  <html>
    <head>{...}</head>
    <body>
      {...}
      <form>
        {...}
        <div id="wrap">
          {...}
          <div id="content">
            {...}
            <div id="main">
              <div id="center">
                <div id="microformat">
                  <div id="hello">
                    <div id="content-wrapper">
                      {...}
                      <div id="zoneRecipe">
                        <div class="ingredients">
                          {...}
                          <div id="zoneIngredients">
                            {...}
                            <div class="ingred-left">
                              <h3>{$ingredients}{/.*/}{/$ingredients}</h3>
                              {...}
                              {many}
                                <ul>
                                  {many}
                                    <li>
                                      <label>
                                        {...}
                                        <p>
                                          <span>{$amount}{/.*/}{/$amount}</span>
                                          <span>{$ingredient}{/.*/}{/$ingredient}</span>
                                        </p>
                                      </label>
                                    </li>
                                  {/many}
                                </ul>
                              {/many}
                              {...but}<ul>{...}</ul>{/...but}
                            </div>
                            {...}
                          </div>
                          {...}
                        </div>
                        {...}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              {...}
            </div>
            {...}
          </div>
          {...}
        </div>
        {...}
      </form>
      {...}
    </body>
  </html>
'

easy_parser = EasyParser.new ep_source do |on|
  on.ingredients do |scope|
    puts "# #{scope['ingredients']}:"
  end

  on.ingredient do |scope|
    puts "- #{scope['amount']} of #{scope['ingredient']}"
  end
end

result, scope = easy_parser.run open('http://allrecipes.com/recipe/grandmas-lemon-meringue-pie/')
p result
