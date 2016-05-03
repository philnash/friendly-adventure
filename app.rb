sms_number = "+447481342184"
voice_number = "+441473379529"

use Rack::TwilioWebhookAuthentication, ENV['AUTH_TOKEN'], '/messages'

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
  light = find_light(client.lights, "4")
  hue = params["Body"].to_i
  light.hue = hue
  "<Response>
    <Message>The light is set to #{hue}!</Message>
  </Response>"
end

post "/voice" do
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

def client
  @client ||= Hue::Client.new
end

def find_light(lights, id)
  lights = client.lights
  light = lights.detect { |l| l.id == id }
end





