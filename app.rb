get "/" do
  lights = client.lights
  erb(:index, :locals => { :lights => lights })
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
  lights = client.lights
  light = lights.detect { |l| l.id == params[:id] }
  light.hue = params["hue"].to_i
  { :light => params[:id], :hue => params["hue"] }.to_json
end

def client
  @client ||= Hue::Client.new
end







