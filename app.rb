Envyable.load("./config/env.yml", "development")

sms_number = "+447481342184"
voice_number = "+441473379529"

use Rack::TwilioWebhookAuthentication, ENV['AUTH_TOKEN'], '/messages'

ForecastIO.configure do |configuration|
  configuration.api_key = ENV["FORECAST_API_KEY"]
end

COLOURS = {
  red: 0,
  green: 26000,
  blue: 42000,
  yellow: 10000
}

NUMBERS = {
  1 => :red,
  2 => :green,
  3 => :blue,
  4 => :yellow
}

get "/" do
  lights = client.lights
  erb(:index, :locals => { :lights => lights })
end

post "/messages" do
  # Change light colour by SMS
  # light = find_light(client.lights, "4")
  # hue = params["Body"].to_i
  # light.hue = hue
  # "<Response>
  #   <Message>The light is set to #{hue}!</Message>
  # </Response>"

  # Change light by temperature at address sent over SMS
  address = params["Body"]
  geodata = Geocoder.search(address).first
  if geodata
    latlong = geodata.data["geometry"]["location"]
    puts latlong
    forecast = ForecastIO.forecast(latlong["lat"], latlong["lng"])
    puts forecast
    actual_temp = forecast.currently.apparentTemperature
    hue = scale_between(actual_temp, 32, 100, 42000, 0).to_i
    puts hue
    light = find_light(client.lights, "4")
    light.hue = hue
    if actual_temp < 55
      message = "Chilly day today!"
    elsif actual_temp < 80
      message = "Lovely day today!"
    else
      message = "Hot stuff!"
    end
    "<Response>
      <Message>#{message}</Message>
    </Response>"
  else
    "<Response>
      <Message>Couldn't find that place, please try again.</Message>
    </Response>"
  end
end

post "/voice" do
  # Set the light colour by dialled phone digits
  if params["Digits"]
    colour = NUMBERS[params["Digits"].to_i]
    welcome = "Thanks, light turned to #{colour}."
    light = find_light(client.lights, "4")
    light.hue = COLOURS[colour]
  else
    welcome = "Welcome to dial a colour. "
  end
  "
  <Response>
    <Gather action='/voice' numDigits='1'>
      <Say loop='0' voice='alice'>#{welcome} Dial one for red. Dial two for green. Dial three for blue. Dial four for yellow...</Say>
    </Gather>
  </Response>
  "
end

post "/toggle/:id" do
  lights = client.lights
  light = lights.detect { |l| l.id == params[:id] }
  if light.on?
    light.off!
    status = "off"
  else
    light.on!
    status = "on"
  end
  if request.xhr?
    { :light => params[:id], :status => status }.to_json
  else
    redirect("/")
  end
end

post "/colour/:id" do
  light = find_light(client.lights, params[:id])
  light.hue = params["hue"].to_i
  { :light => params[:id], :hue => params["hue"] }.to_json
end

post "/github" do
  light = find_light(client.lights, "4")
  light.alert = "select"
  200
end

def client
  @client ||= Hue::Client.new
end

def find_light(lights, id)
  lights = client.lights
  light = lights.detect { |l| l.id == id }
end

def scale_between(number, from_min, from_max, to_min, to_max)
  number = from_min if number < from_min
  number = from_max if number > from_max
  ((to_max - to_min) * (number - from_min)) / (from_max - from_min) + to_min
end



