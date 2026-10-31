// Unity 2021.3 LTS Asset Importer Adapter
// Context: unity | Adapter: v20-21-03

using System;

namespace AllLadsTool.Unity.Adapter
{
    public static class Adapter20213
    {
        public static bool CheckEnvironment()
        {
            Console.WriteLine("[ADAPTER v20-21-03] Initialized for Unity 2021.3 LTS.");
            return true;
        }

        public static void ProcessAsset(string assetPath)
        {
            Console.WriteLine($"[ADAPTER v20-21-03] Processing asset '{assetPath}' using 2021.3 import pipeline...");
        }
    }
}
