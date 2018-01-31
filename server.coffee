###
# Generic server for file conversion on the fly
###

http    = require 'http'
url     = require 'url'
fs      = require 'fs'
less    = require 'less'
Path    = require 'path'
md      = require 'marked'
coffee  = require 'coffeescript'
etag    = require 'etag'

server = http.createServer (req, res) ->
  parsedurl = url.parse req.url, true
  file = parsedurl.pathname
  pretty = parsedurl.query.pretty?
  unless match = file.match /\.(\w+)$/
    res.writeHead 501, 'Not Implemented'
    return res.end "No filename suffix found in \"#{file}\""
  suffix = match[1]
  try
    tag = etag fs.statSync file
  catch
    res.writeHead 404, 'File not found'
    return res.end "#{file} not found"
  res.setHeader 'Etag', tag
  if req.headers['if-none-match'] is tag
    res.writeHead 304, 'Not Modified'
    res.end()
  else
    fs.readFile file, 'utf-8', (err, data) ->
      if err
        console .log err
        res.writeHead 404, 'File not found'
        res.end "#{err.message}"
      else
        switch suffix
          when 'less'
            less.render data,
              paths: [ Path.dirname file ],
              compress: not pretty,
              (e, output) ->
                if e
                  res.writeHead 500, 'Syntax Error'
                  res.end e.message
                else
                  res.writeHead 200,
                    'Content-Type': 'text/css; charset=utf-8'
                  res.end output.css
          when 'markdown', 'md'
            md data, (err, html) ->
              if err
                res.writeHead 500, 'Syntax Error'
                res.end err.toString()
              else
                res.writeHead 200,
                  'Content-TYpe': 'text/html'
                res.end """
                        <html>
                          <head>
                            <title>#{file}</title>
                          </head>
                          <body>
                          #{html}
                          </body>
                        </html>
                        """
          when 'coffee'
            try
              result = coffee.compile data
            catch err
                res.writeHead 500, 'Syntax Error'
                return res.end "Syntax Error: #{err.message}
                  on line #{err.location.first_line}"
            res.writeHead 200,
              'Content-TYpe': 'application/x-javascript'
            res.end result
          else
            res.writeHead 501, 'Not Implemented'
            res.end "Unknown file suffix of \"#{suffix}\""


# server.listen '/var/run/www/on-the-fly.sock'

# server.listen 8000, 'localhost'

server.listen 'systemd'
