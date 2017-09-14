let hover = {
   "position": {
   "character": 16,
   "line": 9
 },
 "textDocument": {
    "uri": "file:///Users/mbulut/projects/rust-by-example/src/main.rs"
 }
}
let messages = [
    {"jsonrpc":"2.0","id":0,"method":"textDocument/hover","params": hover}
];

let cp = require('child_process');

let rls = cp.spawn('/Users/mbulut/.cargo/bin/rls', ['run', 'nightly', 'rls']);
rls.stdout.on('data', function(d) {
    process.stdout.write(d.toString());
});
rls.stderr.on('data', function(d) {
    process.stderr.write(d.toString());
});

function write(index) {
    return function() {
        let m = JSON.stringify(messages[index]);
        m = 'Content-Length: ' + m.length + "\r\n\r\n" + m;
        rls.stdin.write(m, function() {
            if (index == messages.length - 1) {
                return;
            }
            setTimeout(write(++index), 3000);
        });
    }
}

write(0)();