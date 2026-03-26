# Find all packages in the repository
PACKAGES=$(find . -mindepth 1 -maxdepth 3 -type f -name "pubspec.yaml" | sed 's|/pubspec.yaml||')

if [ -z "$PACKAGES" ]; then
    echo "ℹ️ No packages found with pubspec.yaml"
    exit 1
else
    echo "::group::ℹ️ ${#PACKAGES[@]} packages found with pubspec.yaml"
fi

HAS_ERROR=false

# Run gen-l10n on each package
for PACKAGE_DIR in $PACKAGES; do
    echo "::group::ℹ️ Running gen-l10n in $PACKAGE_DIR"
    
    # Navigate to package directory
    pushd "$PACKAGE_DIR" > /dev/null

    # Check for l10n configuration file
    if [ -f "l10n.yaml" ]; then
        CONFIG_FILE="l10n.yaml"
    elif [ -f "l10n.yml" ]; then
        CONFIG_FILE="l10n.yml"
    else
        CONFIG_FILE=""
    fi

    if [ -n "$CONFIG_FILE" ]; then
        # Check if untranslated-messages-file is defined
        if [[ "$FAILS_IF_UNTRANSLATED" == "true" ]]; then
            if ! grep -q "^untranslated-messages-file:" "$CONFIG_FILE"; then
                echo "untranslated-messages-file path not found, adding to $CONFIG_FILE"
                # Add a newline just in case the file doesn't end with one
                echo "" >> "$CONFIG_FILE"
                echo "untranslated-messages-file: untranslated_messages.json" >> "$CONFIG_FILE"
            fi
        fi

        # Run generation
        flutter gen-l10n

        # Check generated files ONLY if configured to check
        if [[ "$FAILS_IF_UNTRANSLATED" == "true" ]]; then
            # Find the configured output file for untranslated messages
            # We assume simple key: value syntax here
            UNTRANSLATED_FILE=$(grep "^untranslated-messages-file:" "$CONFIG_FILE" | cut -d':' -f2 | tr -d ' "' | xargs)

            if [ -n "$UNTRANSLATED_FILE" ]; then
                if [ -f "$UNTRANSLATED_FILE" ]; then
                    content=$(cat "$UNTRANSLATED_FILE")
                    if [ -s "$UNTRANSLATED_FILE" ] && [ "$content" != "{}" ]; then
                        echo "::error::🚨 Untranslated messages found in $PACKAGE_DIR/$UNTRANSLATED_FILE"
                        cat "$UNTRANSLATED_FILE"
                        HAS_ERROR=true
                    else
                        echo "::endgroup::"
                        echo "☑️ Untranslated messages file is empty. Good job!"
                    fi
                else
                    echo "::endgroup::"
                    echo "☑️ No untranslated messages file generated."
                fi
            fi
        fi
    else
        echo "::endgroup::"
        echo "⏭️ No l10n.yaml or l10n.yml found. Skipping."
    fi

    popd > /dev/null
    echo "::endgroup::"
done

if [ "$HAS_ERROR" = true ]; then
    echo "::error::🚨 One or more packages have untranslated messages. Failing the action."
    exit 1
fi


echo "::endgroup::"