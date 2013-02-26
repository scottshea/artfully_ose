class TagJob < Struct.new(:tag, :people)
  def perform
    people.each do |p|
      p.tag_list << tag unless p.tag_list.include? tag
      p.save
    end
  end
end