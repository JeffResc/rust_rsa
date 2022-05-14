local checks = {
  kind: "pipeline",
  type: "docker",
  name: "check",
  steps: [
    {
      name: "check",
      image: "rust",
      commands: [
        "cargo check",
      ],
      volumes: [
        {
          name: "cargo",
          path: "/usr/local/cargo"
        }
      ]
    },
    {
      name: "build-cache",
      image: "meltwater/drone-cache:dev",
      pull: true,
      environment: {
        "AWS_ACCESS_KEY_ID": {
          from_secret: "s3_access_key"
        },
        "AWS_SECRET_ACCESS_KEY": {
          from_secret: "s3_secret_key"
        }
      },
      settings: {
        rebuild: true,
        bucket: "rust_rsa",
        endpoint: {
          from_env: "s3_server"
        },
        "path-style": true,
        mount: ['/usr/local/cargo']
      },
      volumes: [
        {
          name: "cargo",
          path: "/usr/local/cargo"
        }
      ]
    }
  ],
  volumes: [
    {
      name: "cargo",
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
      name: "restore-cache",
      image: "meltwater/drone-cache:dev",
      pull: true,
      environment: {
        "AWS_ACCESS_KEY_ID": {
          from_secret: "s3_access_key"
        },
        "AWS_SECRET_ACCESS_KEY": {
          from_secret: "s3_secret_key"
        }
      },
      settings: {
        restore: true,
        bucket: "rust_rsa",
        endpoint: {
          from_env: "s3_server"
        },
        "path-style": true,
        mount: ['/usr/local/cargo']
      },
      volumes: [
        {
          name: "cargo",
          path: "/usr/local/cargo"
        }
      ]
    },
    {
      name: "install_docker_cross",
      image: "rust",
      volumes: [
        {
          name: "cargo",
          path: "/usr/local/cargo",
        }
      ],
      commands: [
        "curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-18.03.1-ce.tgz | tar zxvf - --strip 1 -C /usr/bin docker/docker",
        "cargo install cross"
      ]
    }
  ],
  volumes: [
    {
      name: "cargo",
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
      name: "restore-cache",
      image: "meltwater/drone-cache:dev",
      pull: true,
      environment: {
        "AWS_ACCESS_KEY_ID": {
          from_secret: "s3_access_key"
        },
        "AWS_SECRET_ACCESS_KEY": {
          from_secret: "s3_secret_key"
        }
      },
      settings: {
        restore: true,
        bucket: "rust_rsa",
        endpoint: {
          from_env: "s3_server"
        },
        "path-style": true,
        mount: ['/usr/local/cargo']
      },
      volumes: [
        {
          name: "cargo",
          path: "/usr/local/cargo"
        }
      ]
    },
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
          name: "cargo",
          path: "/usr/local/cargo"
        }
      ],
      environment: {
        "CROSS_DOCKER_IN_DOCKER": true,
      },
      commands: [
        "cross build --release --target " + arch,
        "tar -czvf /target/rust_rsa-" + arch + ".tar.gz -C target/" + arch + "/release ."
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
    },
    {
      name: "cargo",
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
