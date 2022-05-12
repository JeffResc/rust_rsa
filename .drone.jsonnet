local Pipeline(arch) = {
  kind: "pipeline",
  type: "kubernetes",
  name: "rust-stable-" + arch,
  steps: [
    {
      name: "build-release",
      image: "rust",
      volumes: [
        {
          name: "dockersock",
          path: "/var/run/docker.sock",
          readonly: true,
        },
      ],
      commands: [
        "curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-18.03.1-ce.tgz | tar zxvf - --strip 1 -C /usr/bin docker/docker",
        "cargo install cross",
        "CROSS_DOCKER_IN_DOCKER=true cross build --release --target " + arch,
      ]
    }
  ],
  volumes: [
    {
      name: "dockersock",
      host: {
        path: "/var/run/docker.sock",
      }
    }
  ]
};

[
  Pipeline("aarch64-unknown-linux-gnu"),
  Pipeline("aarch64-unknown-linux-musl"),
  Pipeline("arm-unknown-linux-gnueabi"),
  Pipeline("arm-unknown-linux-gnueabihf"),
  Pipeline("arm-unknown-linux-musleabi"),
  Pipeline("arm-unknown-linux-musleabihf"),
  Pipeline("armv7-unknown-linux-gnueabihf"),
  Pipeline("armv7-unknown-linux-musleabihf"),
  Pipeline("x86_64-pc-windows-gnu"),
  Pipeline("x86_64-unknown-linux-gnu"),
  Pipeline("x86_64-unknown-linux-musl"),
]
