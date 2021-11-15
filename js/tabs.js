const tabs = {
    container: document.getElementById("open_explorers"),
    tabs: {},
    
    add: function(explorer_window_data) {
        const {hwnd, path} = explorer_window_data
        if(!this.tabs.hasOwnProperty(hwnd)) {
            this.create(explorer_window_data);
            } else if(this.tabs.hwnd != path) {
            this.tabs.hwnd = path;
            this.update(explorer_window_data);
        }
    },
    
    remove: function(hwnd) {
        if(this.tabs.hasOwnProperty(hwnd)) {
            delete this.tabs[hwnd];
            const tab = this.container.querySelector(`p[data-hwnd="${hwnd}"]`);
            if(tab) {
                this.container.removeChild(tab);
            }
        }
    },
    
    create: function({hwnd, path}) {
        const folder_name = path.split("\\").pop();
        const tab = document.createElement("p");
        tab.classList.add("tab");
        tab.innerText = folder_name;
        tab.dataset.hwnd = hwnd
        this.container.appendChild(tab);
    },
    
    update: function({hwnd, path}) {
        const folder_name = path.split("\\").pop();
        const tab = this.container.querySelector(`p[data-hwnd="${hwnd}"]`);
        tab.innerText = folder_name;
    },
    
    open: function(hwnd) {
        Array.from(this.container.children).forEach(tab => {
            tab.classList.remove("selected");
            if(tab.dataset.hwnd == hwnd) tab.classList.add("selected");
        });
    },
    
    fromArray: function(explorers) {
        Object.keys(this.tabs).forEach((hwnd) => {
            if(!explorers.some((explorer) => explorer.hwnd == hwnd)) this.remove(hwnd);
        });
        explorers.forEach(explorer => this.add(explorer));
    }
}