import os
import shutil

Elite = ["01116","01157","02058","02078","02141","02216","02293","02323","03059","03060","03081","03088","03140","03221a","03332","03333","03334","04052","04062","04186","04296","04325","04326","04337","05057","05085","05086","05088","05148","05149","05178a","05178c","05178e","05178g","05178i","05178k","05217a","05220","05346","06057","06058","06061","06145","06146","06147","06148","06226","06271","06306","06307","06308","06309","06310","06311","06346","06347","06348","06349","06350","07053","07076","07077","07078","07079","07080","07081","07144","07253","07292","07330","07331","08522","08535","08536","08537","08538","08539","08540","08541","08542","08543","08547","08575","08576","08577","08578","08579","08580","08581","08582","08583","08608","08641","08679","08711","51056","52037","52064","53018","71045","71051","81028","82017","82018","82019","82020","82027","84029","84032","84035","84041","xnyarlathotep"]
def copy_files_with_extension(source_dir, dest_dir, extension):
    # Ensure the destination directory exists
    os.makedirs(dest_dir, exist_ok=True)

    # Iterate over all files in the source directory
    for filename in os.listdir(source_dir):
        # Check if the file ends with the specified extension
        print(filename)
        if filename[:-5] in Elite:
            # Construct full file path
            source_file = os.path.join(source_dir, filename)
            dest_file = os.path.join(dest_dir, filename)
            # Copy the file to the destination directory
            shutil.copy2(source_file, dest_file)
            print(f'Copied: {source_file} to {dest_file}')

# Example usage
source_directory = r'./'  # Replace with your source directory
destination_directory = r'../output'  # Replace with your destination directory
file_extension = 'b.avif'

copy_files_with_extension(source_directory, destination_directory, file_extension)
