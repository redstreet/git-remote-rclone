rclone's crypt backend does not support hashes. This fails with git-remote-rclone.

git-remote-rclone quits because it finds no hash on the server, and assumes the server
to be empty.

To work on backends that don't support hashes:

- easy solution: download and compute the hash manually. This is most inefficient, and
  thus the point of using hashing is lost. However, this is an easy solution to get
  up and working

- Use (encrypted) file size/date to guess whether the hash has changed. Download if so.
  This will produce incorrect results if filesize/date haven't changed and hash has, but
  this is extremely unlikely
  - check if rclone supports filesize/date

- work with a user-supplied function to compute hash. For rclone's crypt, this would
  involve computing the raw underlying file's hash. Not sure if rclone supports this

Meanwhile:
- comment out this line: if repo_hashes == None: return
