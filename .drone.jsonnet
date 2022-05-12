local checks = {
  kind: 'pipeline',
  type: 'docker',
  name: 'check',
  steps: [
    {
      name: 'check',
      image: 'rust',
      commands: [
        "cargo check",
      ]
    }
  ]
};

local install_docker_cross = {
  kind: 'pipeline',
  type: 'docker',
  name: 'install_docker_cross',
  steps: [
    {
      name: 'install_docker_cross',
      image: 'rust',
      commands: [
        "curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-18.03.1-ce.tgz | tar zxvf - --strip 1 -C /usr/bin docker/docker",
        "cargo install cross"
      ]
    }
  ]
};

local build(arch) = {
  kind: "pipeline",
  type: "docker",
  name: "rust-stable-" + arch,
  depends_on: ["check", "install_docker_cross"],
  steps: [
    {
      name: "build",
      image: "rust",
      volumes: [
        {
          name: "dockersock",
          path: "/var/run/docker.sock",
          readonly: true
        }
      ],
      commands: [
        "CROSS_DOCKER_IN_DOCKER=true cross build --release --target " + arch,
        "tar -czvf target/rust_rsa-" + arch + ".tar.gz target/" + arch + "/release"
      ],
      when: {
        branch: [
          "production"
        ]
      }
    },
    {
      name: "publish",
      image: "plugins/github-release",
      settings: {
        "api_key": { from_secret: 'github_token' },
        "files": "target/rust_rsa-" + arch + ".tar.gz"
      },
      when: {
        event: "tag"
      }
    }
  ],
  volumes: [
    {
      name: "dockersock",
      host: {
        path: "/var/run/docker.sock"
      }
    }
  ]
};


[
  checks,
  install_docker_cross,
  build("aarch64-unknown-linux-gnu"),
  build("aarch64-unknown-linux-musl"),
  build("arm-unknown-linux-gnueabi"),
  build("arm-unknown-linux-gnueabihf"),
  build("arm-unknown-linux-musleabi"),
  build("arm-unknown-linux-musleabihf"),
  build("armv7-unknown-linux-gnueabihf"),
  build("armv7-unknown-linux-musleabihf"),
  build("x86_64-pc-windows-gnu"),
  build("x86_64-unknown-linux-gnu"),
  build("x86_64-unknown-linux-musl")
]
