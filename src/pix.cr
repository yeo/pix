require "kemal"
require "crymagick"

module Pix
  VERSION = "0.1.0"
  CAPACITY = 10000
  DB_FILE = ::File.join [Kemal.config.public_folder, "upload", "0.db.txt"]
  DB = Array(String).new(size: CAPACITY, value: "images/tulip.jpg")
  R = Random.new

  def self.config
    Kemal.config.port = 3003

    static_headers do |response, filepath, filestat|
      if filepath =~ /\.(jpg|png)$/
        response.headers.add("Cache-Control", "max-age=86400, public")
      end
    end

  end

  def self.load_data
    if File.exists?(DB_FILE)
      content = File.read_lines(DB_FILE).each do |line|
        DB.shift
        DB.push line
      end
    end

    spawn do
      loop do
        sleep 15.seconds
        save_data
        puts "Write data at #{Time.utc}"
      end
    end
  end

  def self.save_data
    File.write(DB_FILE, DB.join("\n"))
  end

  def self.route
    get "/" do |env|
      id = CAPACITY - 1

      if env.params.query.has_key?("after")
        id = env.params.query["after"].to_i + 1
        if id >= CAPACITY
          id = 0
        end
      end

      if env.params.query.has_key?("before")
        id = env.params.query["before"].to_i - 1
        if id < 0
          id = CAPACITY
        end
      end

      name = DB[id]
      render "src/views/index.ecr"
    end

    post "/incoming" do |env|
      response = ""

      HTTP::FormData.parse(env.request) do |upload|
        filename = upload.filename
        # Be sure to check if file.filename is not empty otherwise it'll raise a compile time error
        if !filename.is_a?(String)
          p "No filename included in upload"
        else
          prefix = Random::Secure.hex(20)
          tmp_file = ::File.join ["/tmp", prefix + "_" + filename]

          File.open(tmp_file, "w") do |f|
            IO.copy(upload.body, f)
          end

          upload_name = "/upload/" + prefix + ".jpg"
          file_path = ::File.join [Kemal.config.public_folder, upload_name]

          image = CryMagick::Image.open(tmp_file)
          if image.type != "JPEG" && image.type != "PNG"
            response += "Invalid image got #{image.type}\n"
            next
          end

          image.resize "1024x1024"
          image.format "jpg"
          image.write file_path

          DB.shift
          DB.push upload_name

          response += "Upload ok\n"
        end
      end

      response
    end

  end

  def self.run
    Kemal.run
  end
end

Pix.config
Pix.route
Pix.load_data
Pix.run
