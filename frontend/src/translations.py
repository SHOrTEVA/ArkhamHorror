import json
import os

def create_template_folder(base_path, template_folder_name="template"):
    template_folder_path = os.path.join(base_path, template_folder_name)
    if not os.path.exists(template_folder_path):
        os.makedirs(template_folder_path)

    def process_directory(source_path, target_path):
        if not os.path.exists(target_path):
            os.makedirs(target_path)
        for item in os.listdir(source_path):
            item_path = os.path.join(source_path, item)
            target_item_path = os.path.join(target_path, item)
            if os.path.isdir(item_path):
                process_directory(item_path, target_item_path)
            elif item.endswith(".json"):
                with open(target_item_path, 'w', encoding='utf-8') as f:
                    json.dump({}, f, ensure_ascii=False, indent=4)
            elif item.endswith(".ts"):
                with open(item_path, 'r', encoding='utf-8') as src_file:
                    with open(target_item_path, 'w', encoding='utf-8') as dest_file:
                        dest_file.write(src_file.read())

    en_folder_path = os.path.join(base_path, "en")
    if os.path.exists(en_folder_path) and os.path.isdir(en_folder_path):
        process_directory(en_folder_path, template_folder_path)

    return template_folder_path

def sync_with_template(base_path, template_folder_name="template"):
    template_folder_path = os.path.join(base_path, template_folder_name)

    def sync_directory(source_path, target_path, folder_name):
        if not os.path.exists(target_path):
            os.makedirs(target_path)
        for item in os.listdir(source_path):
            source_item_path = os.path.join(source_path, item)
            target_item_path = os.path.join(target_path, item)
            if os.path.isdir(source_item_path):
                sync_directory(source_item_path, target_item_path, folder_name)
            else:
                if not os.path.exists(target_item_path):
                    with open(source_item_path, 'r', encoding='utf-8') as src_file:
                        with open(target_item_path, 'w', encoding='utf-8') as dest_file:
                            content = src_file.read()
                            if item.endswith(".ts"):
                                content = content.replace("/en/", f"/{folder_name}/")
                            dest_file.write(content)

    for folder_name in os.listdir(base_path):
        folder_path = os.path.join(base_path, folder_name)
        if os.path.isdir(folder_path) and folder_name != template_folder_name:
            sync_directory(template_folder_path, folder_path, folder_name)

def read_all_campaigns(folder_path):
    campaign_files = [f for f in os.listdir(folder_path) if f.startswith("allCampaigns") and f.endswith(".json")]
    campaigns = {}
    for file in campaign_files:
        with open(os.path.join(folder_path, file), 'r', encoding='utf-8') as f:
            campaigns[file] = json.load(f)
    return campaigns

def read_locale_data(base_path):
    locale_data = {}
    for folder_name in os.listdir(base_path):
        folder_path = os.path.join(base_path, folder_name)
        if os.path.isdir(folder_path):  # Ensure folder_path is a directory
            for sub_folder_name in os.listdir(folder_path):
                sub_folder_path = os.path.join(folder_path, sub_folder_name)
                if os.path.isdir(sub_folder_path):  # Ensure sub_folder_path is a directory
                    for file_name in os.listdir(sub_folder_path):
                        file_path = os.path.join(sub_folder_path, file_name)
                        if file_name == "base.json":
                            with open(file_path, 'r', encoding='utf-8') as f:
                                locale_data.setdefault(folder_name, {}).setdefault(sub_folder_name, {}).update(json.load(f))
    return locale_data

def update_locale_data(base_path, locale_data):
    for key, sub_data in locale_data.items():
        key_path = os.path.join(base_path, key)
        if os.path.isdir(key_path):
            for sub_key, sub_key_data in sub_data.items():
                sub_key_path = os.path.join(key_path, sub_key)
                if os.path.isdir(sub_key_path):
                    base_json_path = os.path.join(sub_key_path, "base.json")
                    with open(base_json_path, 'w', encoding='utf-8') as f:
                        json.dump(sub_key_data, f, ensure_ascii=False, indent=4)

def wrap_paragraphs(text):
    lines = text.split('\n')
    wrapped_lines = []
    for line in lines:
        if line.strip():  # Check if the line contains text
            wrapped_lines.append(f"<p>{line}</p>")
        else:
            wrapped_lines.append(line)  # Preserve empty lines
    return ''.join(wrapped_lines)

campaign_mapping = {
    "core": "nightOfTheZealot",
    "dwl": "theDunwichLegacy",
    "ptc": "thePathToCarcosa",
    "tfa": "theForgottenAge",
    "tcu": "theCircleUndone",
    "tdea": "theDreamEaters",
    "tic": "theInnsmouthConspiracy",
    "eoe": "edgeOfTheEarth"
}

localized_campaign_files = {
    "en": "allCampaigns.json",
    "es": "allCampaigns_es.json",
    "it": "allCampaigns_it.json",
    "ko": "allCampaigns_ko.json",
    "zh": "allCampaigns_zh-cn.json"
}

folder_path = "generated"
campaign_data = read_all_campaigns(folder_path)

locales_path = "locales"
locale_data = read_locale_data(locales_path)

#template_path = create_template_folder(locales_path)

#for key, sub_data in locale_data.items():
#    for subkey, subkey_data in sub_data.items():
#        if "prologue" not in subkey_data:
#            print(f"{key}\\{subkey}")

#print(create_template_folder(locales_path))
template_path = create_template_folder(locales_path)
sync_with_template(locales_path)