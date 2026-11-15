# Player avatars in v0.60

Open **Options > Player Avatar**. Your existing animated gloves and weapon grips stay in their accepted positions when you change the body.

On Quest 2, Quest 3, or Quest 3S, choose **Create avatar (360sona)**. The online editor opens in a headset panel. Create your avatar, choose its **3D model export**, then select **GLB**, **T-pose**, embedded **PNG/JPEG textures**, and no props. CMZ VR captures the normal export, converts it on the headset, and returns to the avatar picker. No Windows converter is needed for this flow. An internet connection is required to use the editor; previously imported avatars remain available offline.

You can also export in Quest Browser and use **Import avatar file** to select the GLB in Downloads. On PC, Create avatar opens the editor in the desktop browser; export GLB and choose Import avatar file. PC conversion also runs inside the game.

Use a complete Xbox 360 avatar with its original 71-bone rig. Raw FBX, external texture files, Draco-compressed meshes, and props attached to a different rig are not supported by the built-in converter. Limits are 32 MiB for GLB input, 60,000 vertices/triangles, 16 materials, and 8 MiB for the converted avatar. Existing `.cmzavatar` models remain supported.

The chosen model is saved locally. Matching CMZ VR peers exchange bounded converted models during a session and can see custom bodies; the original CMZ model remains the fallback. The tracked glove models are retained. Use only content you are allowed to use and share with other players.

360sona is an external editor, not bundled editor source or a project affiliation. Its availability and export options can change. The integrated live editor/export flow and headset fit still require physical Quest acceptance; the reference conversion, animated GPU rendering, and local network transfer have separate automated checks.
