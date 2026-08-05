const { supabase } = require('../config/supabaseClient');

class SupabaseStorageService {
  async uploadFile({ bucket, storagePath, fileBuffer, contentType }) {
    const { data, error } = await supabase.storage.from(bucket).upload(storagePath, fileBuffer, {
      contentType,
      upsert: true,
    });

    if (error) throw error;

    const { data: publicData } = supabase.storage.from(bucket).getPublicUrl(storagePath);

    return publicData.publicUrl;
  }

  async downloadFile({ bucket, storagePath }) {
    const { data, error } = await supabase.storage.from(bucket).download(storagePath);
    if (error) throw error;
    return data;
  }

  async deleteFile({ bucket, storagePath }) {
    const { data, error } = await supabase.storage.from(bucket).remove([storagePath]);
    if (error) throw error;
    return data;
  }
}

module.exports = new SupabaseStorageService();
