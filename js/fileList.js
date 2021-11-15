const file_list = {
    container: document.getElementById("file_explorer"),
    file: [],
    fromArray: function(file_list) {
        this.clear();
        Object.keys(file_list).forEach((path) => {
            const {isDir, ext, name} = file_list[path];
            this.file.push({path: file_list[path], isDir, ext, name});
            
            this.add(path, isDir, name);
        });
    },
    
    add: function (path, isDir, filename) {
        const item = document.createElement("div");
        const name = document.createElement("span");
        const icon = new Image();
        
        const ext = !isDir && filename.includes(".")? filename.split(".").pop() : "";
        
        item.dataset.ext = ext
        item.dataset.isDir = isDir
        item.dataset.path = path
        
        item.className = "file";
        name.innerText = filename;
        
        if(isDir) {
            icon.src = "imgs/folder.png";
        } else
        if(ext == "") {
            icon.src = "imgs/unknown.png";
        }
        
        item.appendChild(icon);
        item.appendChild(name);
        this.container.appendChild(item);
    },
    
    clear: function() {
        Array.from(this.container.children).forEach((item)=>{this.container.removeChild(item)})
        this.files = [];
    }
}