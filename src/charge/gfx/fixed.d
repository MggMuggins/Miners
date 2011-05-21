// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.fixed;

import std.math;
import std.stdio;
static import std.string;

import charge.math.color;
import charge.math.point3d;
import charge.math.vector3d;
import charge.math.matrix4x4d;
import charge.sys.logger;
import charge.gfx.gl;
import charge.gfx.light;
import charge.gfx.camera;
import charge.gfx.cull;
import charge.gfx.renderer;
import charge.gfx.renderqueue;
import charge.gfx.target;
import charge.gfx.shader;
import charge.gfx.texture;
import charge.gfx.material;
import charge.gfx.world;


class FixedRenderer : public Renderer
{
private:
	mixin Logging;

public:
	this()
	{
		l.bug("Created new fixed renderer");
	}

	static bool init()
	{
		// In theory we need to check for VBO's and stuff,
		// but ffs who don't have those now adays?
		return true;
	}

protected:
	void render(Camera c, RenderQueue rq, World w)
	{
		renderTarget.setTarget();
		glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		c.transform();

		renderLoop(rq, w);

		glDisable(GL_DEPTH_TEST);
	}

	void renderLoop(RenderQueue rq, World w)
	{
		Renderable r = rq.pop();

		glAlphaFunc(GL_GEQUAL, 0.5f);

		glEnable(GL_CULL_FACE);
		glCullFace(GL_BACK);

		while(r !is null) {
			Material m = r.getMaterial();

			if (m !is null)
				render(m, r, w);
			else {
				glColor3d(1.0, 1.0, 1.0);
				r.drawFixed();
			}

			r = rq.pop();
		}

		glDisable(GL_CULL_FACE);
	}

	void render(Material m, Renderable r, World w)
	{
		SimpleMaterial sm = cast(SimpleMaterial)m;
		int i;

		if (sm.fake)
			glEnable(GL_ALPHA_TEST);

		foreach(l; w.lights) {
			assert(l !is null);
			auto sl = cast(SimpleLight)l;

			if (sl is null)
				continue;

			render(sm, r, sl);
			i++;
		}

		// Not lit
		if (i == 0) {
			glColor3d(0.0, 0.0, 0.0);
			r.drawFixed();
		}

		if (sm.fake)
			glDisable(GL_ALPHA_TEST);
	}

	void render(SimpleMaterial m, Renderable r)
	{
		if (m.tex is null) {
			glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, m.color.ptr);
			glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, m.color.ptr);
			glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, Color4f.Black.ptr);
			glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, Color4f.Black.ptr);
		} else {
			glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, Color4f.White.ptr);
			glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, Color4f.White.ptr);
			glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, Color4f.Black.ptr);
			glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, Color4f.Black.ptr);

			glActiveTexture(GL_TEXTURE0);
			glEnable(GL_TEXTURE_2D);
			glBindTexture(GL_TEXTURE_2D, m.tex.id);
		}

		r.drawFixed();

		glActiveTexture(GL_TEXTURE0);
		glDisable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, 0);
		glDisable(GL_COLOR_MATERIAL);
	}

	void render(SimpleMaterial m, Renderable r, SimpleLight l)
	{
		activate(l, GL_LIGHT0);

		glEnable(GL_LIGHTING);
		glEnable(GL_LIGHT0);

		if (m.tex is null) {
			glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, m.color.ptr);
			glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, m.color.ptr);
			glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, Color4f.Black.ptr);
			glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, Color4f.Black.ptr);
		} else {
			glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, Color4f.White.ptr);
			glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, Color4f.White.ptr);
			glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, Color4f.Black.ptr);
			glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, Color4f.Black.ptr);

			glActiveTexture(GL_TEXTURE0);
			glEnable(GL_TEXTURE_2D);
			glBindTexture(GL_TEXTURE_2D, m.tex.id);
		}

		r.drawFixed();

		glActiveTexture(GL_TEXTURE0);
		glDisable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, 0);
		glDisable(GL_COLOR_MATERIAL);

		glDisable(GL_LIGHT0);
		glDisable(GL_LIGHTING);
	}

	void activate(SimpleLight l, int id)
	{
		GLfloat temp[4];
		Vector3d h = l.rotation.rotateHeading();

		h.scale(-1); // Flip
		temp[0] = cast(float)h.x;
		temp[1] = cast(float)h.y;
		temp[2] = cast(float)h.z;
		temp[3] = 0.0f; // zero here to make it a dir light.

		glLightfv(id, GL_POSITION, temp.ptr);

		glLightfv(id, GL_AMBIENT, l.ambient.ptr);
		glLightfv(id, GL_DIFFUSE, l.diffuse.ptr);
		glLightfv(id, GL_SPECULAR, l.specular.ptr);

		glLightf(id, GL_CONSTANT_ATTENUATION, 0.0f);
		glLightf(id, GL_LINEAR_ATTENUATION, 0.0f);
		glLightf(id, GL_QUADRATIC_ATTENUATION, 0.0f);
	}

}
