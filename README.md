# Roadmap.sh-006
### Simple File Integrity Checker

#### Requirements:

```bash``` obviously and ```openssl```

#### Make script executable:

```chmod +x file-integrity.sh```

### How to use:

```file-integrity.sh save```
will prompt you for a password and files you want to save state for. Creates a ```mapping_file``` in ```$GOOD_STATE_DIR``` which stores the map of saved files and their corresponding ```checksum``` values encrypted in ```.enc```. 

You can change the path in ```$GOOD_STATE_DIR``` for customization.


```file-integrity.sh check```
will prompt you for previously saved password and files you want to check saved state for.
Uses ```sha256sum``` to run against the input files and warns if ```checksum``` has a ```mismatch``` since last saved value was recorded or gives green if ```integrity``` of the files are still the same.

Note: You must remember password used as this script does not save this anywhere!


Part of this challenge: https://roadmap.sh/projects/file-integrity-checker
