local checks = {
  kind: "pipeline",
  type: "docker",
  name: "check",
  steps: [
    {
      name: "check",
      image: "rust",
      volumes: [
        {
          name: "target",
          path: "/target",
        }
      ],
      environment: {
        CARGO_TARGET_DIR: "/target"
      },
      commands: [
        "cargo check",
      ]
    }
  ],
  volumes: [
    {
      name: "target",
      temp: {}
    }
  ]
};

local install_docker_cross = {
  kind: "pipeline",
  type: "docker",
  name: "install_docker_cross",
  when: {
    event: "tag"
  },
  depends_on: [
    "check"
  ],
  steps: [
    {
      name: "install_docker_cross",
      image: "rust",
      volumes: [
        {
          name: "target",
          path: "/target",
        }
      ],
      environment: {
        CARGO_TARGET_DIR: "/target"
      },
      commands: [
        "curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-18.03.1-ce.tgz | tar zxvf - --strip 1 -C /usr/bin docker/docker",
        "cargo install cross"
      ]
    }
  ],
  volumes: [
    {
      name: "target",
      temp: {}
    }
  ]
};

local build(arch) = {
  kind: "pipeline",
  type: "docker",
  name: "rust-stable-" + arch,
  depends_on: [
    "install_docker_cross"
  ],
  when: {
    event: "tag"
  },
  steps: [
    {
      name: "build",
      image: "rust",
      volumes: [
        {
          name: "dockersock",
          path: "/var/run/docker.sock",
          readonly: true
        },
        {
          name: "target",
          path: "/target",
        }
      ],
      environment: {
        CARGO_TARGET_DIR: "/target"
      },
      commands: [
        "CROSS_DOCKER_IN_DOCKER=true cross build --release --target " + arch,
        "tar -czvf /target/rust_rsa-" + arch + ".tar.gz -C /target/" + arch + "/release ."
      ],
    },
    {
      name: "publish",
      image: "plugins/github-release",
      volumes: [
        {
          name: "target",
          path: "/target",
        }
      ],
      settings: {
        "api_key": { from_secret: "github_token" },
        "files": "/target/rust_rsa-" + arch + ".tar.gz"
      },
    }
  ],
  volumes: [
    {
      name: "dockersock",
      host: {
        path: "/var/run/docker.sock"
      }
    },
    {
      name: "target",
      temp: {}
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
