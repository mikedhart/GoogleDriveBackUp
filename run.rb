require "rubygems"
require "google_drive"
require "yaml"

config = YAML::load_file(Dir.pwd + "/config.yml")
session = GoogleDrive.login(config['username'], config['password'])

`mysqldump -u #{config['mysqluser']} -#{config['mysqlpassword']} --all-databases | gzip > #{config['backupdir']}/#{Time.now.to_i}.sql.gz`

for file in Dir.entries(config['backupdir'])
	next if file == '.' or file == '..'
	
	# First we check if the file is newer than the last time we ran. If it is, we will upload it. If not we will ignore it
	if (File.mtime(config['backupdir'] + '/' + file) > Time.at(config['lastrun'])) then
		puts "Uploading #{file}"
		session.upload_from_file(config['backupdir'] + "/" + file, file, :convert => false)
		puts "Done."
	end

	# Now, if the file is older than 7 days, we will delete it.
	if (File.mtime(config['backupdir'] + '/' + file) < (Time.at(config['lastrun']) - (86400*7))) then
		puts "Deleting #{file}"
		File.unlink(config['backupdir'] + '/' + file)	
		puts "Done"	
	end
end

config['lastrun'] = Time.now.to_i
File.open(Dir.pwd + "/config.yml", 'w') {|f| f.write config.to_yaml }
