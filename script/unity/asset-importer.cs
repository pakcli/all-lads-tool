// Universal Asset Importer Orchestrator (Context: unity)
// Delegates version-specific import pipelines to adapter/

using System;
using AllLadsTool.Unity.Adapter;

namespace AllLadsTool.Unity
{
    public class AssetImporter
    {
        public static void Main(string[] args)
        {
            string targetAsset = args.Length > 0 ? args[0] : "Assets/Models/sample.fbx";
            
            // Dynamic check: Default to 2022.3 LTS adapter
            Adapter20223.CheckEnvironment();
            Adapter20223.ProcessAsset(targetAsset);
            
            Console.WriteLine("[OK] Unity asset pipeline processed successfully.");
        }
    }
}
