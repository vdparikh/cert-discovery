#!/bin/bash

# Initialize an array to store certificate information
declare -a certificates

# Error handling function
handle_error() {
    local message="$1"
    echo "Error: $message" >&2
    exit 1
}

# Search for PEM files on the system
find_pem_files() {
    local search_dirs=( "/another/possible/directory" "/etc/ssl")

    for dir in "${search_dirs[@]}"; do
        if [ -d "$dir" ]; then
            while IFS= read -r pem_file; do
                process_pem_file "$pem_file"
            done < <(find "$dir" -type f \( -iname "*.pem" -o -iname "*.crt" \))
        fi
    done
}

# Process a PEM file
process_pem_file() {
    local pem_file="$1"
    if [ -f "$pem_file" ]; then
        echo "Processing PEM file: $pem_file"

        # Use OpenSSL to get certificate information
        local subject
        local issuer
        local thumbprint
        local expiration_date

        subject=$(openssl x509 -noout -subject -in "$pem_file")
        issuer=$(openssl x509 -noout -issuer -in "$pem_file")
        thumbprint=$(openssl x509 -noout -fingerprint -in "$pem_file" | cut -d'=' -f2)
        expiration_date=$(openssl x509 -noout -enddate -in "$pem_file" | cut -d'=' -f2)
        local cert_info="{
            \"Path\": \"$pem_file\",
            \"Subject\": \"$subject\",
            \"Issuer\": \"$issuer\",
            \"Thumbprint\": \"$thumbprint\",
            \"ExpirationDate\": \"$expiration_date\"
        }"

        certificates+=("$cert_info")  # Append certificate info to the global array
    else
        handle_error "PEM file not found: $pem_file"
    fi
}

find_keystore_files() {
    local search_dirs=("/path/to/possible/keystore/directories" "/another/possible/directory")
    
    for dir in "${search_dirs[@]}"; do
        if [ -d "$dir" ]; then
            find "$dir" -type f \( -iname "*.jks" -o -iname "*.p12" \) -print | while read -r keystore_file; do
                process_keystore "$keystore_file"
            done
        fi
    done
}

# Process a Java keystore file
process_keystore() {
    local keystore_file="$1"
    if [ -f "$keystore_file" ]; then
        echo "Processing keystore file: $keystore_file"
        
        # Use keytool to list certificates in the keystore
        while IFS= read -r entry; do
            if [ "$entry" != "" ]; then
                cert_info=$(keytool -list -v -keystore "$keystore_file" -storepass changeit -alias "$entry" 2>/dev/null)
                if [ $? -eq 0 ]; then
                    certificates+=("$cert_info")
                else
                    handle_error "Failed to list certificates in $keystore_file"
                fi
            fi
        done < <(keytool -list -keystore "$keystore_file" -storepass changeit -v 2>/dev/null | grep 'Alias name:')
    else
        handle_error "Keystore file not found: $keystore_file"
    fi
}

# Search for PEM files
find_pem_files

# Output the certificate information in JSON format if certificates were found
if [ ${#certificates[@]} -eq 0 ]; then
    handle_error "No certificates found"
else
    echo "[" > certificate_inventory.json
    for ((i=0; i<${#certificates[@]}; i++)); do
        echo "${certificates[$i]}" >> certificate_inventory.json
        if [[ $i -lt $((${#certificates[@]}-1)) ]]; then
            echo "," >> certificate_inventory.json
        fi
    done
    echo "]" >> certificate_inventory.json

    echo "Certificate inventory has been saved to certificate_inventory.json"
fi
