<pre>
require "rubygems"
require "google_drive"
require "yaml"
</pre>

<p>There are three dependencies. Ruby gems (obviously), the <a href="https://github.com/gimite/google-drive-ruby" target="_blank">awesome Google Drive gem</a> which will upload the files for us and finally, YAML. I store my configurations in a YAML file. This way, I can deploy this script across multiple servers.</p>

<pre>config = YAML::load_file(Dir.pwd + "/config.yml")</pre>

<p>The above loads the contents of the config file into a Ruby hash</p>

<pre>`mysqldump -u #{config['mysqluser']} -#{config['mysqlpassword']} --all-databases | gzip > #{config['backupdir']}/#{Time.now.to_i}.sql.gz`</pre>

<p>This will connect to your MySQL database, and dump a snapshot of all the databases into an sql file. Finally, we name the file according to the current UNIX time stamp and store as a gzip. Notice how the line above uses the config variables for the MySQL username and password and backup directory.</p>

<pre>
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
</pre>

<p>Loop through every file in the backup directory. If the file has been created since the script last ran, upload it to Google Drive and if it was created over 7 days ago, delete it.</p>
