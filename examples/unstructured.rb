# encoding: UTF-8

require_relative '../parser'
require 'open-uri'

ep_source = '
  <html>
    <head>{...}</head>
    <body>
      {...}
      <h2>{$title}{/.*/}{/$title}</h2>
      {...}
      <h4>{$subtitle}{/.*/}{/$subtitle}</h4>
      {...}
      {many}
        <h4>{$section}{/SECCI[ÓO]N .+/}{/$section}</h4>
        {many}
          {...but}<h4>{/SECCI[ÓO]N .+/}</h4>{/...but}
          <h4>{$chapter}{/CAP[ÍI]TULO .+/}{/$chapter}</h4>
            {many}
              {...but}<h4>{/(SECCI[ÓO]N .+|CAP[ÍI]TULO .+)/}</h4>{/...but}
              <p><u><a>{$article_item}{/.+/}{/$article_item}</a></u>{$article_text}{/.+/}{/$article_text}</p>
              {...but}<p><u><a>{/.+/}</a></u>{/.+/}</p>{/...but}
            {/many}
          {...but}<h4>{/CAP[ÍI]TULO .+/}</h4>{/...but}
        {/many}
      {/many}
    </body>
  </html>
'

easy_parser = EasyParser.new ep_source do |on|
  on.article_text do |scope|
    section_number = /SECCI[ÓO]N (.+)/.match(scope['section'])[1]
    chapter_number = /CAP[ÍI]TULO (.+)/.match(scope['chapter'])[1]
    article_number = /([0-9]+)/.match(scope['article_item'])[1]
    article_text = scope['article_text'][0..9]
    puts "#{section_number},#{chapter_number},#{article_number},\"#{article_text}\""
  end
end

result, scope = easy_parser.run open('http://www.parlamento.gub.uy/Constituciones/Const004.htm'), 'iso-8859-1'
