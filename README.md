<p>There is a common phrase among system administrators when it comes to backing up data. This phrase is "no data exists until it is stored in three places". In reality, this is not true of course but if you come up with a worst case scenario in your head, I'm sure you'll understand the phrase. I use Google Drive for many reasons. But the main reason is convenience. I can back up my databases and post them to Google Drive in one script. Moreover, this is all I need to do to have my data exist in three places.</p>
<ol>
<li>The server</li>
<li>Google Drive</li>
<li>My computer at home</li>
</ol>
<p>Yep, that's right. One script with one simple post and the data exists in three places. Of course there are other reasons to use Google Drive as a backup service. I can browse the contents of my SQL files without having to download them, the UI is nice and I have a unified billing system because I store other backups in Google Drive as well as MySQL backups.</p>

<p>In terms of strategy then, here is what I do. I take a backup daily, once every 12 hours. I dump the contents of my databases into a single SQL file which I then gzip and store in a backups folder on the server itself. After this, I look for any new files that have been created since the last time the script ran and I upload these files to my Google Drive account. Finally, while I'm in the back up folder, I delete any files that are more than 7 days old. This way I can quickly restore a file within the past week if I need to, but I know that if I need to go back more than a week, I can do so from Google Drive</p>

<p>Let's take a look at how the script works.</p>

<pre>
require "rubygems"
require "google_drive"
require "yaml"
</pre>

<p>There are three dependencies. Ruby gems (obviously), the <a href="https://github.com/gimite/google-drive-ruby" target="_blank">awesome Google Drive gem</a> which will upload the files for us and finally, YAML. I store my configurations in a YAML file. This way, I can deploy this script across multiple servers.</p>

<pre>config = YAML::load_file(Dir.pwd + "/config.yml")</pre>

<p>The above loads the contents of the config file into a Ruby hash</p>

<pre>`mysqldump -u #{config['mysqluser']} -#{config['mysqlpassword']} --all-databases | gzip > #{config['backupdir']}/#{Time.now.to_i}.sql.gz`</pre>

<p>So, the first real operation of the script. This will connect to your MySQL database, and dump a snapshot of all the databases into an sql file. Finally, we name the file according to the current UNIX time stamp and store as a gzip. Notice how the line above uses the config variables for the MySQL username and password and backup directory.</p>

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

<p>Now, the script loops through every file in the backup directory. If the file has been created since the script last ran, it will upload it to Google Drive and if it was created over 7 days ago, it will be deleted.</p>
