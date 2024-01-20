import { parseArgs } from 'https://deno.land/std@0.208.0/cli/parse_args.ts';
import { LockFile, SteamObject, parseObject } from './parser.ts'

const utf8Decoder = new TextDecoder();

/**
 * Recursively find all files matching `fileName` under `baseDir`
 * 
 * @param baseDir Directory to recursively search for all files matching `fileName`
 * @param fileName Name of file to try to find
 * @returns A list of paths to files matching `fileName`
 */
const findFiles = async (baseDir: string, fileName: string) => {
  const files: string[] = [];
  for await (const dirEntry of Deno.readDir(baseDir)) {
    if (dirEntry.isDirectory) {
      const subDirFiles = await findFiles(`${baseDir}/${dirEntry.name}`, fileName)
      files.push(...subDirFiles);
    } else if (dirEntry.isFile && dirEntry.name == fileName) {
      files.push(`${baseDir}/${dirEntry.name}`);
    }
  }

  return files;
};

const getAppInfo = async (appId: number): Promise<SteamObject> => {
  const steamcmd = new Deno.Command("steamcmd", {
    args: [ 
      "+login", "anonymous",
      "+app_info_print", `${appId}`,
      "+quit"
    ],
  });
  const app_info_bytes = (await steamcmd.output()).stdout;
  const app_info_str = utf8Decoder.decode(app_info_bytes);
  const info_start = `"${appId}"`;
  const info_start_idx = app_info_str.indexOf(info_start);
  const app_info_obj = app_info_str.slice(info_start_idx + info_start.length);
  return parseObject(app_info_obj);
}

async function updateLockFile(
  path: string,
  args: { "add-to-store": boolean; "dry-run": boolean; }
) {
  const data: LockFile = JSON.parse(await Deno.readTextFile(path));
  const { appId, depotId, name } = data;

  console.log(`Checking appId: ${appId} for updates...`);

  const appInfo: any = await getAppInfo(appId);

  const { manifests } = appInfo.depots[depotId];
  for (const branch of Object.keys(manifests)) {
    const buildId = appInfo.depots.branches[branch].buildid;
    const manifestId = manifests[branch].gid;

    data.branches = data.branches || {};
    data.builds = data.builds || {};

    if (data.branches[branch] != buildId) {
      console.log(`${appId} ${branch} has new build ${buildId}`);
      data.branches[branch] = buildId;
    }
    if (!data.builds[buildId]) {
      let hash = "";
      if (!args['dry-run']) {
        console.log(`Prefetching build: ${buildId}`);
        hash = await prefetch(
          name,
          `${appId}`,
          `${depotId}`,
          manifestId,
          branch != "public" ? branch : "",
          args['add-to-store']
        );
      }
      data.builds[buildId] = {
        hash,
        manifestId,
        version: buildId,
      };
    }

    // Flush after each branch to allow for partial updates when attempting to
    // update many packages/branches
    if (!args['dry-run']) {
      await Deno.writeTextFile(path, JSON.stringify(data, null, 2));
    }
  }  
}

const main = async () => {
  const args = parseArgs(Deno.args, {
    alias: {
      "d": "dry-run"
    },
    boolean: ["add-to-store", "dry-run", "help"],
    negatable: ["add-to-store"]
  });
  
  if (args.help) {
    usage();
  }

  let lockFiles: string[];
  if (args._.length > 0) {
    lockFiles = args._.map(p => p.toString());
  } else {
    lockFiles = await findFiles("./pkgs", "lock.json");
  }

  for (const path of lockFiles) {
    try {
      await updateLockFile(path, args);
    } catch(e) {
      console.error(`Failed to update ${path}`, e);
    }
  }
}

main();


async function prefetch(
  name: string,
  appId: string,
  depotId: string, 
  manifestId: string, 
  branch: string,
  addToStore: boolean,
): Promise<string> {
  const command = new Deno.Command("./apps/updater/prefetch.sh", {
      env: {
          appId, depotId, manifestId, branch,
          name: `${name}-depot`,
          addToStore: addToStore ? "true" : "",
      },
      stderr: 'inherit',
  });
  const output = await command.output();

  if (!output.success) {
    console.error(utf8Decoder.decode(output.stdout));
    throw new Error(`Prefetching failed with code ${output.code}`);
  }

  return utf8Decoder
    .decode(output.stdout)
    .trim();
}

function usage(): never {
  console.log(
    "Usage: update-servers [OPTION]... [FILE]...\n" +
    "Update lock files with latest versions from Steam API\n" +
    "\n" +
    "With no FILE, recurssively search for all lock.json files under ./pkgs\n" +
    "\n" +
    "  --add-to-store     Add new versions to nix store after prefetching\n" +
    "  -d, --dry-run      Check Steam API for updates, but don't pretech and update lock files\n" +
    ""
  );
  Deno.exit(0);
}