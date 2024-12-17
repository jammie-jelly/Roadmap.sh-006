#!/usr/bin/env bash

GOOD_STATE_DIR="$HOME/.stuff/sys-integrity-2"
MAPPING_FILE="$GOOD_STATE_DIR/mapping_file"
TEMP_DIR=$(mktemp -d)

print_mapping_file_creation_date() {
    if [ -e "$MAPPING_FILE" ]; then
        creation_date=$(stat --format='%w' "$MAPPING_FILE")
        if [ "$creation_date" == "?" ]; then
            echo "⚠️  No known save date"
        else
            echo "🤖 Last checkin date: $creation_date"
        fi
    fi
}

prompt_for_password() {
    read -s -p "Enter password: " password
    echo >&2
    echo "$password"
}

generate_random_filename() {
    echo "$(openssl rand -hex 12).enc"
}

save_good_state() {
    local file="$1" password="$2" checksum random_filename encrypted_file temp_input temp_output

    # Remove old encrypted files and mapped entries
    encrypted_file=$(grep -F "$file:" "$MAPPING_FILE" 2>/dev/null | cut -d':' -f2-)
    if [ -n "$encrypted_file" ]; then
        rm -f "$GOOD_STATE_DIR/$encrypted_file"
        grep -vF "$file:" "$MAPPING_FILE" > "$MAPPING_FILE.tmp" && mv "$MAPPING_FILE.tmp" "$MAPPING_FILE"
    fi

    checksum=$(sha256sum "$file" | cut -d' ' -f1)

    random_filename=$(generate_random_filename)
    encrypted_file="$GOOD_STATE_DIR/$random_filename"

    mkdir -p "$GOOD_STATE_DIR" || { echo "❌ Error creating directory $GOOD_STATE_DIR"; exit 1; }

    temp_input="$TEMP_DIR/$(basename "$file").tmp"
    echo -e "$checksum\n$(cat "$file")" > "$temp_input"

    temp_output="$TEMP_DIR/$random_filename"
    openssl enc -aes-256-cbc -salt -pbkdf2 -in "$temp_input" -out "$temp_output" -pass pass:"$password" || { echo "❌ Error encrypting $file"; exit 1; }
    mv "$temp_output" "$encrypted_file"

    # Save the mapping with the relative filename
    relative_filename=$(echo "$encrypted_file" | sed "s|$GOOD_STATE_DIR/||")
    echo "$file:$relative_filename" >> "$MAPPING_FILE"

    # Clean up temporary input file
    rm -f "$temp_input"
}

check_for_changes() {
    local file="$1" password="$2" encrypted_file saved_checksum saved_content current_checksum
    relative_encrypted_file=$(grep -F "$file:" "$MAPPING_FILE" | cut -d':' -f2-)
    if [ -n "$relative_encrypted_file" ]; then
        encrypted_file="$GOOD_STATE_DIR/$relative_encrypted_file"

        temp_decrypted="$TEMP_DIR/$(basename "$file").decrypted"
        if openssl enc -d -aes-256-cbc -salt -pbkdf2 -in "$encrypted_file" -out "$temp_decrypted" -pass pass:"$password" >/dev/null 2>&1; then
            saved_checksum=$(head -n 1 "$temp_decrypted")
            saved_content=$(tail -n +2 "$temp_decrypted")
            current_checksum=$(sha256sum "$file" | cut -d' ' -f1)

            if [ "$current_checksum" == "$saved_checksum" ]; then
                echo "✅ No changes detected for $file"
            else
                echo "⚠️ Changes detected for $file (Checksum mismatch)"
            fi
        else
            echo "Wrong password"
            rm -f "$temp_decrypted"
            exit 1
        fi
        rm -f "$temp_decrypted"
    else
        echo "🤖🤖🤖 Saved encrypted good state not found for $file. Run the script with 'save' option first. 🤖🤖🤖"
    fi
}

if [[ "$1" == "save" || "$1" == "check" ]]; then
    print_mapping_file_creation_date
    password=$(prompt_for_password)
    
    # Prompt the user for file paths
    echo "Enter the file paths (comma-separated): "
    read -r input_files
    IFS=',' read -r -a FILES <<< "$input_files"  # Split input into array

    for file in "${FILES[@]}"; do
        file=$(echo "$file" | xargs)  # Trim whitespace
        if [[ "$1" == "save" ]]; then
            save_good_state "$file" "$password"
        elif [[ "$1" == "check" ]]; then
            check_for_changes "$file" "$password"
        fi
    done
else
    echo "Usage: $0 [save|check]"
fi

rm -rf "$TEMP_DIR"
